class Api::V1::QuestionsController < Api::V1::ApiController
  before_action :authenticate_api_v1_user!
  before_action :set_question, only: [:update, :destroy]
  before_action :set_form  
  before_action :allow_only_owner, only: [:create, :update, :destroy]

  def update
    ActiveRecord::Base.transaction do
      @question.update(question_params)
      if @questions_to_update.present?
        @questions_to_update.each do |question| 
          question.save
        end
      end
    end
    render json: @question
  end

  def create
    @question = Question.create(question_params.merge(form: @form))
    render json: @question
  end

  def destroy
    @question.destroy
    render json: {message: 'ok'}
  end

  private

    def set_question
      @question = Question.find(params[:id])  
      
      if params[:action] = 'update'
        @new_position = params[:position]
        if @new_position.present? && @question.position.present?
          set_questions_to_update
        end
      end
    end

    def set_questions_to_update
      if @new_position > @question.position
        @questions_to_update = Question.where("form_id = ? AND position > ? AND position <= ?", 
          @question.form_id, @question.position, @new_position)                
      elsif @new_position < @question.position
        @questions_to_update = Question.where("form_id = ? AND position >= ? AND position < ?", 
          @question.form_id, @new_position, @question.position)
      end

      if (@questions_to_update.present?)
        @questions_to_update.each do |question|
          question.position -= 1 if @new_position > @question.position
          question.position += 1 if @new_position < @question.position         
        end
      end
    end

    def set_form
      @form = (@question)? @question.form : Form.find(params[:form_id])          
    end

    def allow_only_owner
      unless current_api_v1_user == @form.user
        render(json: {}, status: :forbidden) and return
      end
    end

    def question_params
      params.require(:question).permit(:title, :kind, :required, :position)          
    end
end