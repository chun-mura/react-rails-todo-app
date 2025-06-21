class TodosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_todo, only: [:show, :update, :destroy]

  def index
    todos = current_user.todos.order(created_at: :desc)
    render json: { todos: todos }
  end

  def show
    render json: @todo
  end

  def create
    todo = current_user.todos.build(todo_params)

    if todo.save
      render json: { todo: todo }, status: :created
    else
      render json: { errors: todo.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @todo.update(todo_params)
      render json: { todo: @todo }
    else
      render json: { errors: @todo.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @todo.destroy
    head :no_content
  end

  private

  def set_todo
    @todo = current_user.todos.find(params[:id])
  end

  def todo_params
    params.permit(:title, :description, :completed)
  end
end
