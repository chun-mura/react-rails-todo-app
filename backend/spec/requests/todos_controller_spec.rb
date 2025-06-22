require 'rails_helper'

RSpec.describe TodosController, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'GET /api/todos' do
    let!(:user_todos) { create_list(:todo, 3, user: user) }
    let!(:other_todos) { create_list(:todo, 2, user: other_user) }

    context 'with valid token' do
      it 'returns only user todos' do
        get '/api/todos', headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response['todos'].length).to eq(3)
        expect(json_response['todos'].map { |todo| todo['id'] }).to match_array(user_todos.map(&:id))
      end

      it 'returns todos ordered by created_at desc' do
        get '/api/todos', headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        todo_ids = json_response['todos'].map { |todo| todo['id'] }
        expect(todo_ids).to eq(user_todos.sort_by(&:created_at).reverse.map(&:id))
      end
    end

    context 'without token' do
      it 'returns unauthorized error' do
        get '/api/todos'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/todos/:id' do
    let(:todo) { create(:todo, user: user) }

    context 'with valid token and own todo' do
      it 'returns the todo' do
        get "/api/todos/#{todo.id}", headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response['id']).to eq(todo.id)
        expect(json_response['title']).to eq(todo.title)
      end
    end

    context 'with valid token but other user todo' do
      let(:other_todo) { create(:todo, user: other_user) }

      it 'returns not found error' do
        get "/api/todos/#{other_todo.id}", headers: auth_headers(user)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without token' do
      it 'returns unauthorized error' do
        get "/api/todos/#{todo.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/todos' do
    let(:valid_params) do
      {
        title: 'Test Todo',
        description: 'Test Description',
        completed: false
      }
    end

    context 'with valid parameters' do
      it 'creates a new todo' do
        expect {
          post '/api/todos', params: valid_params, headers: auth_headers(user)
        }.to change(Todo, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['todo']['title']).to eq('Test Todo')
        expect(json_response['todo']['description']).to eq('Test Description')
        expect(json_response['todo']['completed']).to be false
        expect(json_response['todo']['user_id']).to eq(user.id)
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        post '/api/todos', params: { title: '' }, headers: auth_headers(user)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include("Title can't be blank")
      end
    end

    context 'without token' do
      it 'returns unauthorized error' do
        post '/api/todos', params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/todos/:id' do
    let(:todo) { create(:todo, user: user) }
    let(:update_params) { { title: 'Updated Todo', completed: true } }

    context 'with valid parameters and own todo' do
      it 'updates the todo' do
        put "/api/todos/#{todo.id}", params: update_params, headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response['todo']['title']).to eq('Updated Todo')
        expect(json_response['todo']['completed']).to be true
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        put "/api/todos/#{todo.id}", params: { title: '' }, headers: auth_headers(user)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include("Title can't be blank")
      end
    end

    context 'with other user todo' do
      let(:other_todo) { create(:todo, user: other_user) }

      it 'returns not found error' do
        put "/api/todos/#{other_todo.id}", params: update_params, headers: auth_headers(user)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without token' do
      it 'returns unauthorized error' do
        put "/api/todos/#{todo.id}", params: update_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/todos/:id' do
    let!(:todo) { create(:todo, user: user) }

    context 'with valid token and own todo' do
      it 'deletes the todo' do
        expect {
          delete "/api/todos/#{todo.id}", headers: auth_headers(user)
        }.to change(Todo, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'with other user todo' do
      let(:other_todo) { create(:todo, user: other_user) }

      it 'returns not found error' do
        delete "/api/todos/#{other_todo.id}", headers: auth_headers(user)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without token' do
      it 'returns unauthorized error' do
        delete "/api/todos/#{todo.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
