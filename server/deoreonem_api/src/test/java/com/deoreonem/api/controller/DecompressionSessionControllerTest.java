package com.deoreonem.api.controller;

import com.deoreonem.api.dto.*;
import com.deoreonem.api.exception.*;
import com.deoreonem.api.service.DecompressionSessionService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.*;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(DecompressionSessionController.class)
@DisplayName("DecompressionSessionController tests")
class DecompressionSessionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private DecompressionSessionService service;

    private final UUID sessionId = UUID.randomUUID();
    private final UUID itemId = UUID.randomUUID();
    private final OffsetDateTime now = OffsetDateTime.now(ZoneOffset.UTC);

    @Test
    @DisplayName("POST /decompression-sessions returns 201")
    void createSession_returns201() throws Exception {
        SessionResponse response = new SessionResponse(sessionId, "IN_PROGRESS", null, now, now);
        when(service.createSession()).thenReturn(response);

        mockMvc.perform(post("/api/v1/decompression-sessions")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.sessionId").value(sessionId.toString()))
                .andExpect(jsonPath("$.data.status").value("IN_PROGRESS"));
    }

    @Test
    @DisplayName("POST /decompression-sessions/{sessionId}/items returns 201")
    void addItem_returns201() throws Exception {
        ItemResponse response = new ItemResponse(itemId, sessionId, "Test", null, false, 1, now, now);
        when(service.addItem(eq(sessionId), any(AddItemRequest.class))).thenReturn(response);

        String body = objectMapper.writeValueAsString(new AddItemRequest("Test"));

        mockMvc.perform(post("/api/v1/decompression-sessions/{sessionId}/items", sessionId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.itemId").value(itemId.toString()));
    }

    @Test
    @DisplayName("PATCH /decompression-items/{itemId}/category returns 200")
    void updateCategory_returns200() throws Exception {
        ItemResponse response = new ItemResponse(itemId, sessionId, "Test", "NOW", false, 1, now, now);
        when(service.updateCategory(eq(itemId), any(UpdateCategoryRequest.class))).thenReturn(response);

        String body = objectMapper.writeValueAsString(new UpdateCategoryRequest("NOW"));

        mockMvc.perform(patch("/api/v1/decompression-items/{itemId}/category", itemId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.category").value("NOW"));
    }

    @Test
    @DisplayName("PATCH /decompression-sessions/{sessionId}/first-action returns 200")
    void setFirstAction_returns200() throws Exception {
        FirstActionResponse response = new FirstActionResponse(sessionId, itemId);
        when(service.setFirstAction(eq(sessionId), any(SetFirstActionRequest.class))).thenReturn(response);

        String body = objectMapper.writeValueAsString(new SetFirstActionRequest(itemId));

        mockMvc.perform(patch("/api/v1/decompression-sessions/{sessionId}/first-action", sessionId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.firstActionItemId").value(itemId.toString()));
    }

    @Test
    @DisplayName("POST /decompression-sessions/{sessionId}/complete returns 200")
    void completeSession_returns200() throws Exception {
        CompleteSessionResponse response = new CompleteSessionResponse(sessionId, "COMPLETED", now);
        when(service.completeSession(sessionId)).thenReturn(response);

        mockMvc.perform(post("/api/v1/decompression-sessions/{sessionId}/complete", sessionId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("COMPLETED"));
    }

    @Test
    @DisplayName("GET /decompression-sessions/{sessionId}/summary returns 200")
    void getSummary_returns200() throws Exception {
        Map<String, List<ItemResponse>> itemsByCategory = new LinkedHashMap<>();
        itemsByCategory.put("NOW", List.of());
        SummaryResponse response = new SummaryResponse(sessionId, "IN_PROGRESS", 0, null, itemsByCategory);
        when(service.getSummary(sessionId)).thenReturn(response);

        mockMvc.perform(get("/api/v1/decompression-sessions/{sessionId}/summary", sessionId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.sessionId").value(sessionId.toString()));
    }

    @Test
    @DisplayName("GET /decompression-sessions/{sessionId}/review returns 200")
    void getReview_returns200() throws Exception {
        ReviewResponse response = new ReviewResponse(sessionId, List.of());
        when(service.getReview(sessionId)).thenReturn(response);

        mockMvc.perform(get("/api/v1/decompression-sessions/{sessionId}/review", sessionId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.sessionId").value(sessionId.toString()));
    }

    @Test
    @DisplayName("Error response returns correct envelope shape for SessionNotFoundException")
    void errorResponse_sessionNotFound_correctEnvelope() throws Exception {
        when(service.getSummary(sessionId)).thenThrow(
                new SessionNotFoundException("Session with id '" + sessionId + "' was not found."));

        mockMvc.perform(get("/api/v1/decompression-sessions/{sessionId}/summary", sessionId))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("SESSION_NOT_FOUND"))
                .andExpect(jsonPath("$.error.message").exists());
    }

    @Test
    @DisplayName("Error response returns correct envelope for SessionAlreadyCompleteException")
    void errorResponse_sessionAlreadyComplete_correctEnvelope() throws Exception {
        when(service.completeSession(sessionId)).thenThrow(
                new SessionAlreadyCompleteException("Session " + sessionId + " is already completed."));

        mockMvc.perform(post("/api/v1/decompression-sessions/{sessionId}/complete", sessionId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("SESSION_ALREADY_COMPLETE"));
    }

    @Test
    @DisplayName("Validation error returns 400 with correct envelope")
    void validationError_blankContent_returns400() throws Exception {
        String body = "{\"content\": \"\"}";

        mockMvc.perform(post("/api/v1/decompression-sessions/{sessionId}/items", sessionId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("VALIDATION_ERROR"));
    }
}
