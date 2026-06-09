package com.deoreonem.api.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.Contact;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SwaggerConfig {

    @Bean
    public OpenAPI deoreonemOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("DeoReoNem API")
                        .description("덜어냄 — Digital Decompression REST API. " +
                                "All endpoints are under /api/v1. " +
                                "Spring Security is deferred to Phase 5; no authentication required in MVP 0.1.")
                        .version("0.1.0")
                        .contact(new Contact()
                                .name("DeoReoNem Team")));
    }
}
