package com.example.todo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import com.example.todo.repository.TodoRepository;

@SpringBootApplication
public class SpringBootTodoAppApplication implements CommandLineRunner
{
@Autowired
public TodoRepository todoRepository;
public static void main(String[] args) {
SpringApplication.run(SpringBootTodoAppApplication.class, args);
}

@Override
public void run(String... args) throws Exception {
	// Application starts with no sample data
}
}
