import React, { createContext, useContext, useState, ReactNode, useCallback } from 'react';
import axios from '../lib/axios';

interface Todo {
  id: number;
  title: string;
  completed: boolean;
  created_at: string;
  updated_at: string;
}

interface TodoContextType {
  todos: Todo[];
  loading: boolean;
  error: string | null;
  fetchTodos: () => Promise<void>;
  addTodo: (title: string) => Promise<void>;
  updateTodo: (id: number, updates: Partial<Todo>) => Promise<void>;
  deleteTodo: (id: number) => Promise<void>;
  toggleTodo: (id: number) => Promise<void>;
}

const TodoContext = createContext<TodoContextType | undefined>(undefined);

export const useTodo = () => {
  const context = useContext(TodoContext);
  if (context === undefined) {
    throw new Error('useTodo must be used within a TodoProvider');
  }
  return context;
};

interface TodoProviderProps {
  children: ReactNode;
}

export const TodoProvider: React.FC<TodoProviderProps> = ({ children }) => {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchTodos = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await axios.get('/api/todos');
      setTodos(response.data.todos);
    } catch (error: any) {
      setError(error.response?.data?.error || 'タスクの取得に失敗しました');
    } finally {
      setLoading(false);
    }
  }, []);

  const addTodo = useCallback(async (title: string) => {
    setError(null);
    try {
      const response = await axios.post('/api/todos', { title });
      setTodos(prev => [...prev, response.data.todo]);
    } catch (error: any) {
      setError(error.response?.data?.error || 'タスクの追加に失敗しました');
      throw error;
    }
  }, []);

  const updateTodo = useCallback(async (id: number, updates: Partial<Todo>) => {
    setError(null);
    try {
      const response = await axios.put(`/api/todos/${id}`, updates);
      setTodos(prev => prev.map(todo =>
        todo.id === id ? response.data.todo : todo
      ));
    } catch (error: any) {
      setError(error.response?.data?.error || 'タスクの更新に失敗しました');
      throw error;
    }
  }, []);

  const deleteTodo = useCallback(async (id: number) => {
    setError(null);
    try {
      await axios.delete(`/api/todos/${id}`);
      setTodos(prev => prev.filter(todo => todo.id !== id));
    } catch (error: any) {
      setError(error.response?.data?.error || 'タスクの削除に失敗しました');
      throw error;
    }
  }, []);

  const toggleTodo = useCallback(async (id: number) => {
    const todo = todos.find(t => t.id === id);
    if (todo) {
      await updateTodo(id, { completed: !todo.completed });
    }
  }, [todos, updateTodo]);

  const value = {
    todos,
    loading,
    error,
    fetchTodos,
    addTodo,
    updateTodo,
    deleteTodo,
    toggleTodo,
  };

  return (
    <TodoContext.Provider value={value}>
      {children}
    </TodoContext.Provider>
  );
};
