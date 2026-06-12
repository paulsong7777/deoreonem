package com.deoreonem.api.service;

import com.deoreonem.api.domain.Category;
import com.deoreonem.api.domain.DecompressionItem;
import com.deoreonem.api.domain.DecompressionSession;
import com.deoreonem.api.dto.*;
import com.deoreonem.api.exception.*;
import com.deoreonem.api.mapper.DecompressionItemMapper;
import com.deoreonem.api.mapper.DecompressionSessionMapper;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class DecompressionSessionService {

    private final DecompressionSessionMapper sessionMapper;
    private final DecompressionItemMapper itemMapper;

    public DecompressionSessionService(DecompressionSessionMapper sessionMapper,
                                       DecompressionItemMapper itemMapper) {
        this.sessionMapper = sessionMapper;
        this.itemMapper = itemMapper;
    }

    public SessionResponse createSession() {
        DecompressionSession session = new DecompressionSession();
        session.setSessionId(UUID.randomUUID());
        session.setStatus("IN_PROGRESS");
        OffsetDateTime now = OffsetDateTime.now(ZoneOffset.UTC);
        session.setCreatedAt(now);
        session.setUpdatedAt(now);

        sessionMapper.insertSession(session);

        return new SessionResponse(
                session.getSessionId(),
                session.getStatus(),
                session.getFirstActionItemId(),
                session.getCreatedAt(),
                session.getUpdatedAt()
        );
    }

    public ItemResponse addItem(UUID sessionId, AddItemRequest request) {
        DecompressionSession session = getSessionOrThrow(sessionId);
        assertSessionNotCompleted(session);

        Integer maxSortOrder = itemMapper.getMaxSortOrder(sessionId);
        int nextSortOrder = (maxSortOrder == null) ? 1 : maxSortOrder + 1;

        DecompressionItem item = new DecompressionItem();
        item.setItemId(UUID.randomUUID());
        item.setSessionId(sessionId);
        item.setContent(request.getContent());
        item.setSortOrder(nextSortOrder);
        OffsetDateTime now = OffsetDateTime.now(ZoneOffset.UTC);
        item.setCreatedAt(now);
        item.setUpdatedAt(now);

        itemMapper.insertItem(item);

        return toItemResponse(item, session.getFirstActionItemId());
    }

    public ItemResponse updateCategory(UUID itemId, UpdateCategoryRequest request) {
        String category = request.getCategory();
        if (!Category.isValid(category)) {
            throw new InvalidCategoryException("Invalid category: " + category);
        }

        DecompressionItem item = getItemOrThrow(itemId);
        DecompressionSession session = getSessionOrThrow(item.getSessionId());

        // Allow only DROP transition for reviewable items in completed sessions (let-go action)
        if ("COMPLETED".equals(session.getStatus())) {
            if (!"DROP".equals(category)) {
                throw new SessionAlreadyCompleteException(
                        "Session " + session.getSessionId() + " is already completed.");
            }
            // Only allow reviewable categories to transition to DROP
            String currentCategory = item.getCategory();
            if (currentCategory == null || "NOW".equals(currentCategory) || "DROP".equals(currentCategory)) {
                throw new SessionAlreadyCompleteException(
                        "Session " + session.getSessionId() + " is already completed.");
            }
        } else {
            assertSessionNotCompleted(session);
        }

        itemMapper.updateCategory(itemId, category);
        item.setCategory(category);

        return toItemResponse(item, session.getFirstActionItemId());
    }

    public FirstActionResponse setFirstAction(UUID sessionId, SetFirstActionRequest request) {
        DecompressionSession session = getSessionOrThrow(sessionId);
        assertSessionNotCompleted(session);

        UUID itemId = request.getItemId();
        DecompressionItem item = getItemOrThrow(itemId);

        if (!item.getSessionId().equals(sessionId)) {
            throw new ItemNotInSessionException(
                    "Item " + itemId + " does not belong to session " + sessionId);
        }

        if (!Category.isFirstActionEligible(item.getCategory())) {
            throw new FirstActionIneligibleException(
                    "Item with category '" + item.getCategory() + "' is not eligible for First Action");
        }

        sessionMapper.updateFirstAction(sessionId, itemId);

        return new FirstActionResponse(sessionId, itemId);
    }

    public CompleteSessionResponse completeSession(UUID sessionId) {
        DecompressionSession session = getSessionOrThrow(sessionId);
        assertSessionNotCompleted(session);

        OffsetDateTime now = OffsetDateTime.now(ZoneOffset.UTC);
        sessionMapper.updateStatus(sessionId, "COMPLETED");
        sessionMapper.updateCompletedAt(sessionId, now);

        return new CompleteSessionResponse(sessionId, "COMPLETED", now);
    }

    public SummaryResponse getSummary(UUID sessionId) {
        DecompressionSession session = getSessionOrThrow(sessionId);
        List<DecompressionItem> items = itemMapper.findBySessionIdOrderBySortOrder(sessionId);

        UUID firstActionItemId = session.getFirstActionItemId();

        // Build items by category map
        Map<String, List<ItemResponse>> itemsByCategory = new LinkedHashMap<>();
        for (Category cat : Category.values()) {
            itemsByCategory.put(cat.name(), new ArrayList<>());
        }

        ItemResponse firstActionItem = null;

        for (DecompressionItem item : items) {
            ItemResponse resp = toItemResponse(item, firstActionItemId);
            String cat = item.getCategory();
            if (cat != null && itemsByCategory.containsKey(cat)) {
                itemsByCategory.get(cat).add(resp);
            }
            if (item.getItemId().equals(firstActionItemId)) {
                firstActionItem = resp;
            }
        }

        return new SummaryResponse(
                sessionId,
                session.getStatus(),
                items.size(),
                firstActionItem,
                itemsByCategory
        );
    }

    public ReviewResponse getReview(UUID sessionId) {
        DecompressionSession session = getSessionOrThrow(sessionId);
        List<DecompressionItem> items = itemMapper.findBySessionIdOrderBySortOrder(sessionId);

        UUID firstActionItemId = session.getFirstActionItemId();

        List<ItemResponse> reviewItems = items.stream()
                .filter(item -> !Category.DROP.name().equals(item.getCategory()))
                .map(item -> toItemResponse(item, firstActionItemId))
                .collect(Collectors.toList());

        return new ReviewResponse(sessionId, reviewItems);
    }

    // --- Helper methods ---

    private DecompressionSession getSessionOrThrow(UUID sessionId) {
        DecompressionSession session = sessionMapper.findById(sessionId);
        if (session == null) {
            throw new SessionNotFoundException("Session with id '" + sessionId + "' was not found.");
        }
        return session;
    }

    private DecompressionItem getItemOrThrow(UUID itemId) {
        DecompressionItem item = itemMapper.findById(itemId);
        if (item == null) {
            throw new ItemNotFoundException("Item with id '" + itemId + "' was not found.");
        }
        return item;
    }

    private void assertSessionNotCompleted(DecompressionSession session) {
        if ("COMPLETED".equals(session.getStatus())) {
            throw new SessionAlreadyCompleteException(
                    "Session " + session.getSessionId() + " is already completed.");
        }
    }

    private ItemResponse toItemResponse(DecompressionItem item, UUID firstActionItemId) {
        boolean isFirstAction = item.getItemId().equals(firstActionItemId);
        return new ItemResponse(
                item.getItemId(),
                item.getSessionId(),
                item.getContent(),
                item.getCategory(),
                isFirstAction,
                item.getSortOrder(),
                item.getCreatedAt(),
                item.getUpdatedAt()
        );
    }
}
