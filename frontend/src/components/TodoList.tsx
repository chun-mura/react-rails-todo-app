import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useTodo } from '../contexts/TodoContext';
import TodoItem from './TodoItem';

const TodoList: React.FC = () => {
  const [newTodo, setNewTodo] = useState('');
  const { user, logout } = useAuth();
  const { todos, loading, error, fetchTodos, addTodo } = useTodo();

  useEffect(() => {
    if (user) {
      fetchTodos();
    }
  }, [user, fetchTodos]);

  const handleAddTodo = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTodo.trim()) return;
    await addTodo(newTodo.trim());
    setNewTodo('');
  };

  return (
    <div className="container">
      <div className="todo-list-header">
        <h1>Todo List</h1>
        <button onClick={logout} className="btn logout-btn">
          ログアウト
        </button>
      </div>
      <p>こんにちは、{user?.email}さん！</p>

      {error && <div className="error">{error}</div>}

      <form onSubmit={handleAddTodo} className="add-todo">
        <input
          type="text"
          value={newTodo}
          onChange={(e) => setNewTodo(e.target.value)}
          placeholder="新しいタスクを追加..."
          disabled={loading}
        />
        <button type="submit" className="btn" disabled={loading || !newTodo.trim()}>
          追加
        </button>
      </form>

      <div className="todo-list">
        {loading && <p>読み込み中...</p>}

        {!loading && todos.length === 0 && (
          <p>タスクがありません。</p>
        )}

        {todos.map((todo) => (
          <TodoItem key={todo.id} todo={todo} />
        ))}
      </div>
    </div>
  );
};

export default TodoList;
