package com.deoreonem.api.controller;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

import com.deoreonem.api.config.CorsConfig;
import com.deoreonem.api.config.SwaggerConfig;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(HealthController.class)
@Import({CorsConfig.class, SwaggerConfig.class})
@DisplayName("HealthController tests")
class HealthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("GET /api/v1/health returns 200 with expected fields")
    void healthEndpointReturns200() throws Exception {
        mockMvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(content().contentType("application/json"))
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.service").value("deoreonem-api"))
                .andExpect(jsonPath("$.version").value("0.1.0"));
    }

    @Test
    @DisplayName("GET /api/v1/health response does not contain success/error envelope")
    void healthEndpointHasNoErrorFields() throws Exception {
        mockMvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.error").doesNotExist());
    }
}
