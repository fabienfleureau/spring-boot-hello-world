package com.example.demo

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
class DemoApplication {
	@RequestMapping("/hello")
	fun home() = "Hello Docker World"
}

fun main(args: Array<String>) {
	runApplication<DemoApplication>(*args)
}
