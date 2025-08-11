package com.example.todo.repository;

import org.springframework.data.repository.PagingAndSortingRepository;
import org.springframework.stereotype.Repository;
import com.example.todo.domain.Todo;
@Repository
public interface TodoRepository extends PagingAndSortingRepository<Todo,
Long>{

}
