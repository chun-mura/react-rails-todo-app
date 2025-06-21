import React, { useState } from 'react';
import { useTodo } from '../contexts/TodoContext';

interface Todo {
  id: number;
  title: string;
  completed: boolean;
  created_at: string;
  updated_at: string;
}

interface TodoItemProps {
  todo: Todo;
}

const TodoItem: React.FC<TodoItemProps> = ({ todo }) => {
  const [isEditing, setIsEditing] = useState(false);
  const [editTitle, setEditTitle] = useState(todo.title);
  const { updateTodo, deleteTodo, toggleTodo } = useTodo();

  const handleToggle = async () => {
    await toggleTodo(todo.id);
  };

  const handleEdit = async () => {
    if (editTitle.trim() && editTitle !== todo.title) {
      await updateTodo(todo.id, { title: editTitle.trim() });
    }
    setIsEditing(false);
  };

  const handleDelete = async () => {
    if (window.confirm('このタスクを削除しますか？')) {
      await deleteTodo(todo.id);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleEdit();
    } else if (e.key === 'Escape') {
      setEditTitle(todo.title);
      setIsEditing(false);
    }
  };

  return (
    <div className={`todo-item ${todo.completed ? 'completed' : ''}`}>
      <input
        type="checkbox"
        checked={todo.completed}
        onChange={handleToggle}
        className="todo-checkbox"
      />

      {isEditing ? (
        <input
          type="text"
          value={editTitle}
          onChange={(e) => setEditTitle(e.target.value)}
          onBlur={handleEdit}
          onKeyDown={handleKeyPress}
          autoFocus
          className="todo-text"
        />
      ) : (
        <span className="todo-text" onDoubleClick={() => setIsEditing(true)}>
          {todo.title}
        </span>
      )}

      <div className="todo-actions">
        <button
          onClick={() => setIsEditing(!isEditing)}
          className="btn-small btn-secondary"
        >
          {isEditing ? '保存' : '編集'}
        </button>
        <button
          onClick={handleDelete}
          className="btn-small btn-danger"
        >
          削除
        </button>
      </div>
    </div>
  );
};

export default TodoItem;
