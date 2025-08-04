package co.sohamds.spring.todo.domain;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;

@Entity
public class Todo {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private long id;
    private String todoItem;
    private String completed;

    public Todo() {
    }

    public Todo(String todoItem, String completed) {
        this.todoItem = todoItem;
        this.completed = completed;
    }

    public Todo(long id, String todoItem, String completed) {
        this.id = id;
        this.todoItem = todoItem;
        this.completed = completed;
    }

    // Builder method
    public static TodoBuilder builder() {
        return new TodoBuilder();
    }

    public static class TodoBuilder {
        private long id;
        private String todoItem;
        private String completed;

        public TodoBuilder id(long id) {
            this.id = id;
            return this;
        }

        public TodoBuilder todoItem(String todoItem) {
            this.todoItem = todoItem;
            return this;
        }

        public TodoBuilder completed(String completed) {
            this.completed = completed;
            return this;
        }

        public Todo build() {
            return new Todo(id, todoItem, completed);
        }
    }

    // Getters and setters
    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public String getTodoItem() {
        return todoItem;
    }

    public void setTodoItem(String todoItem) {
        this.todoItem = todoItem;
    }

    public String getCompleted() {
        return completed;
    }

    public void setCompleted(String completed) {
        this.completed = completed;
    }

    @Override
    public String toString() {
        return "Todo{" +
                "id=" + id +
                ", todoItem='" + todoItem + '\'' +
                ", completed='" + completed + '\'' +
                '}';
    }
}