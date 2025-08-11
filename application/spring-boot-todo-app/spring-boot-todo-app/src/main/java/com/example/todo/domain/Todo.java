package com.example.todo.domain;

import javax.persistence.Entity;

import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;

import lombok.Data;
@Data
@Entity
public class Todo {
@Id
@GeneratedValue(strategy = GenerationType.AUTO)
private long id;
private String todoItem;
private String completed;

public Todo() {
	// Default constructor for JPA
}

public Todo(String todoItem, String completed) {
	super();
	this.todoItem = todoItem;
	this.completed = completed;
}

// Manual getters and setters (Lombok backup)
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

public long getId() {
	return id;
}

public void setId(long id) {
	this.id = id;
}

// Builder pattern methods
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
		Todo todo = new Todo();
		todo.id = this.id;
		todo.todoItem = this.todoItem;
		todo.completed = this.completed;
		return todo;
	}
}

}
