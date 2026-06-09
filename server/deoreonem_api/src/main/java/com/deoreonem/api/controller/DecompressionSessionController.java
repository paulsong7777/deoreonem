package com.deoreonem.api.controller;

import com.deoreonem.api.dto.*;
import com.deoreonem.api.service.DecompressionSessionService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class DecompressionSessionController {

    private final DecompressionSessionService service;

    public DecompressionSessionController(DecompressionSessionService service) {
        this.service = service;
    }

    @PostMapping("/decompression-sessions")
    public ResponseEntity<ApiResponse<SessionResponse>> createSession() {
        SessionResponse data = service.createSession();
        return ResponseEntity.status(HttpStatus.CREATED).body(new ApiResponse<>(data));
    }

    @PostMapping("/decompression-sessions/{sessionId}/items")
    public ResponseEntity<ApiResponse<ItemResponse>> addItem(
            @PathVariable UUID sessionId,
            @Valid @RequestBody AddItemRequest request) {
        ItemResponse data = service.addItem(sessionId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(new ApiResponse<>(data));
    }

    @PatchMapping("/decompression-items/{itemId}/category")
    public ResponseEntity<ApiResponse<ItemResponse>> updateCategory(
            @PathVariable UUID itemId,
            @Valid @RequestBody UpdateCategoryRequest request) {
        ItemResponse data = service.updateCategory(itemId, request);
        return ResponseEntity.ok(new ApiResponse<>(data));
    }

    @PatchMapping("/decompression-sessions/{sessionId}/first-action")
    public ResponseEntity<ApiResponse<FirstActionResponse>> setFirstAction(
            @PathVariable UUID sessionId,
            @Valid @RequestBody SetFirstActionRequest request) {
        FirstActionResponse data = service.setFirstAction(sessionId, request);
        return ResponseEntity.ok(new ApiResponse<>(data));
    }

    @PostMapping("/decompression-sessions/{sessionId}/complete")
    public ResponseEntity<ApiResponse<CompleteSessionResponse>> completeSession(
            @PathVariable UUID sessionId) {
        CompleteSessionResponse data = service.completeSession(sessionId);
        return ResponseEntity.ok(new ApiResponse<>(data));
    }

    @GetMapping("/decompression-sessions/{sessionId}/summary")
    public ResponseEntity<ApiResponse<SummaryResponse>> getSummary(
            @PathVariable UUID sessionId) {
        SummaryResponse data = service.getSummary(sessionId);
        return ResponseEntity.ok(new ApiResponse<>(data));
    }

    @GetMapping("/decompression-sessions/{sessionId}/review")
    public ResponseEntity<ApiResponse<ReviewResponse>> getReview(
            @PathVariable UUID sessionId) {
        ReviewResponse data = service.getReview(sessionId);
        return ResponseEntity.ok(new ApiResponse<>(data));
    }
}
