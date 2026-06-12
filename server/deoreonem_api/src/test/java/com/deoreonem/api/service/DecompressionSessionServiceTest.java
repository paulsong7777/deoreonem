package com.deoreonem.api.service;

import com.deoreonem.api.domain.Category;
import com.deoreonem.api.domain.DecompressionItem;
import com.deoreonem.api.domain.DecompressionSession;
import com.deoreonem.api.dto.*;
import com.deoreonem.api.exception.*;
import com.deoreonem.api.mapper.DecompressionItemMapper;
import com.deoreonem.api.mapper.DecompressionSessionMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("DecompressionSessionService tests")
class DecompressionSessionServiceTest {

    @Mock
    private DecompressionSessionMapper sessionMapper;

    @Mock
    private DecompressionItemMapper itemMapper;

    @InjectMocks
    private DecompressionSessionService service;

    private DecompressionSession inProgressSession;
    private DecompressionSession completedSession;
    private UUID sessionId;
    private UUID itemId;

    @BeforeEach
    void setUp() {
        sessionId = UUID.randomUUID();
        itemId = UUID.randomUUID();

        inProgressSession = new DecompressionSession();
        inProgressSession.setSessionId(sessionId);
        inProgressSession.setStatus("IN_PROGRESS");
        inProgressSession.setCreatedAt(OffsetDateTime.now(ZoneOffset.UTC));
        inProgressSession.setUpdatedAt(OffsetDateTime.now(ZoneOffset.UTC));

        completedSession = new DecompressionSession();
        completedSession.setSessionId(sessionId);
        completedSession.setStatus("COMPLETED");
        completedSession.setCreatedAt(OffsetDateTime.now(ZoneOffset.UTC));
        completedSession.setUpdatedAt(OffsetDateTime.now(ZoneOffset.UTC));
    }

    @Test
    @DisplayName("createSession returns valid SessionResponse with status IN_PROGRESS")
    void createSession_returnsInProgressSession() {
        SessionResponse response = service.createSession();

        assertNotNull(response.getSessionId());
        assertEquals("IN_PROGRESS", response.getStatus());
        assertNull(response.getFirstActionItemId());
        assertNotNull(response.getCreatedAt());
        assertNotNull(response.getUpdatedAt());
        verify(sessionMapper).insertSession(any(DecompressionSession.class));
    }

    @Test
    @DisplayName("addItem assigns sort_order 1 for first item")
    void addItem_firstItem_sortOrderIsOne() {
        when(sessionMapper.findById(sessionId)).thenReturn(inProgressSession);
        when(itemMapper.getMaxSortOrder(sessionId)).thenReturn(null);

        AddItemRequest request = new AddItemRequest("Test item");
        ItemResponse response = service.addItem(sessionId, request);

        assertEquals(1, response.getSortOrder());
        assertEquals("Test item", response.getContent());
        verify(itemMapper).insertItem(any(DecompressionItem.class));
    }

    @Test
    @DisplayName("addItem assigns sort_order max+1 for subsequent items")
    void addItem_subsequentItem_sortOrderIsMaxPlusOne() {
        when(sessionMapper.findById(sessionId)).thenReturn(inProgressSession);
        when(itemMapper.getMaxSortOrder(sessionId)).thenReturn(3);

        AddItemRequest request = new AddItemRequest("Fourth item");
        ItemResponse response = service.addItem(sessionId, request);

        assertEquals(4, response.getSortOrder());
    }

    @Test
    @DisplayName("addItem on COMPLETED session throws SessionAlreadyCompleteException")
    void addItem_completedSession_throwsException() {
        when(sessionMapper.findById(sessionId)).thenReturn(completedSession);

        AddItemRequest request = new AddItemRequest("Test item");

        assertThrows(SessionAlreadyCompleteException.class,
                () -> service.addItem(sessionId, request));
    }

    @Test
    @DisplayName("updateCategory with valid category succeeds")
    void updateCategory_validCategory_succeeds() {
        DecompressionItem item = createItem(sessionId, itemId, null);
        when(itemMapper.findById(itemId)).thenReturn(item);
        when(sessionMapper.findById(sessionId)).thenReturn(inProgressSession);

        UpdateCategoryRequest request = new UpdateCategoryRequest("TOMORROW");
        ItemResponse response = service.updateCategory(itemId, request);

        assertEquals("TOMORROW", response.getCategory());
        verify(itemMapper).updateCategory(itemId, "TOMORROW");
    }

    @Test
    @DisplayName("updateCategory with invalid category throws InvalidCategoryException")
    void updateCategory_invalidCategory_throwsException() {
        UpdateCategoryRequest request = new UpdateCategoryRequest("INVALID");

        assertThrows(InvalidCategoryException.class,
                () -> service.updateCategory(itemId, request));
    }

    @Test
    @DisplayName("setFirstAction with eligible category succeeds")
    void setFirstAction_eligibleCategory_succeeds() {
        DecompressionItem item = createItem(sessionId, itemId, "NOW");
        when(sessionMapper.findById(sessionId)).thenReturn(inProgressSession);
        when(itemMapper.findById(itemId)).thenReturn(item);

        SetFirstActionRequest request = new SetFirstActionRequest(itemId);
        FirstActionResponse response = service.setFirstAction(sessionId, request);

        assertEquals(sessionId, response.getSessionId());
        assertEquals(itemId, response.getFirstActionItemId());
        verify(sessionMapper).updateFirstAction(sessionId, itemId);
    }

    @Test
    @DisplayName("setFirstAction with ineligible category DROP throws FirstActionIneligibleException")
    void setFirstAction_dropCategory_throwsException() {
        DecompressionItem item = createItem(sessionId, itemId, "DROP");
        when(sessionMapper.findById(sessionId)).thenReturn(inProgressSession);
        when(itemMapper.findById(itemId)).thenReturn(item);

        SetFirstActionRequest request = new SetFirstActionRequest(itemId);

        assertThrows(FirstActionIneligibleException.class,
                () -> service.setFirstAction(sessionId, request));
    }

    @Test
    @DisplayName("setFirstAction with ineligible category WAITING throws FirstActionIneligibleException")
    void setFirstAction_waitingCategory_throwsException() {
        DecompressionItem item = createItem(sessionId, itemId, "WAITING");
        when(sessionMapper.findById(sessionId)).thenReturn(inProgressSession);
        when(itemMapper.findById(itemId)).thenReturn(item);

        SetFirstActionRequest request = new SetFirstActionRequest(itemId);

        assertThrows(FirstActionIneligibleException.class,
                () -> service.setFirstAction(sessionId, request));
    }

    @Test
    @DisplayName("setFirstAction with ineligible category MEMO throws FirstActionIneligibleException")
    void setFirstAction_memoCategory_throwsException() {
        DecompressionItem item = createItem(sessionId, itemId, "MEMO");
        when(sessionMapper.findById(sessionId)).thenReturn(inProgressSession);
        when(itemMapper.findById(itemId)).thenReturn(item);

        SetFirstActionRequest request = new SetFirstActionRequest(itemId);

        assertThrows(FirstActionIneligibleException.class,
                () -> service.setFirstAction(sessionId, request));
    }

    @Test
    @DisplayName("setFirstAction with ineligible category WORRY_ONLY throws FirstActionIneligibleException")
    void setFirstAction_worryOnlyCategory_throwsException() {
        DecompressionItem item = createItem(sessionId, itemId, "WORRY_ONLY");
        when(sessionMapper.findById(sessionId)).thenReturn(inProgressSession);
        when(itemMapper.findById(itemId)).thenReturn(item);

        SetFirstActionRequest request = new SetFirstActionRequest(itemId);

        assertThrows(FirstActionIneligibleException.class,
                () -> service.setFirstAction(sessionId, request));
    }

    @Test
    @DisplayName("setFirstAction with null category throws FirstActionIneligibleException")
    void setFirstAction_nullCategory_throwsException() {
        DecompressionItem item = createItem(sessionId, itemId, null);
        when(sessionMapper.findById(sessionId)).thenReturn(inProgressSession);
        when(itemMapper.findById(itemId)).thenReturn(item);

        SetFirstActionRequest request = new SetFirstActionRequest(itemId);

        assertThrows(FirstActionIneligibleException.class,
                () -> service.setFirstAction(sessionId, request));
    }

    @Test
    @DisplayName("setFirstAction with item from different session throws ItemNotInSessionException")
    void setFirstAction_itemFromDifferentSession_throwsException() {
        UUID otherSessionId = UUID.randomUUID();
        DecompressionItem item = createItem(otherSessionId, itemId, "NOW");
        when(sessionMapper.findById(sessionId)).thenReturn(inProgressSession);
        when(itemMapper.findById(itemId)).thenReturn(item);

        SetFirstActionRequest request = new SetFirstActionRequest(itemId);

        assertThrows(ItemNotInSessionException.class,
                () -> service.setFirstAction(sessionId, request));
    }

    @Test
    @DisplayName("completeSession on already-completed session throws SessionAlreadyCompleteException")
    void completeSession_alreadyCompleted_throwsException() {
        when(sessionMapper.findById(sessionId)).thenReturn(completedSession);

        assertThrows(SessionAlreadyCompleteException.class,
                () -> service.completeSession(sessionId));
    }

    @Test
    @DisplayName("getSummary groups items by category correctly")
    void getSummary_groupsItemsByCategory() {
        UUID item1Id = UUID.randomUUID();
        UUID item2Id = UUID.randomUUID();
        UUID item3Id = UUID.randomUUID();

        DecompressionItem item1 = createItem(sessionId, item1Id, "NOW");
        item1.setSortOrder(1);
        DecompressionItem item2 = createItem(sessionId, item2Id, "TOMORROW");
        item2.setSortOrder(2);
        DecompressionItem item3 = createItem(sessionId, item3Id, "NOW");
        item3.setSortOrder(3);

        inProgressSession.setFirstActionItemId(item1Id);
        when(sessionMapper.findById(sessionId)).thenReturn(inProgressSession);
        when(itemMapper.findBySessionIdOrderBySortOrder(sessionId)).thenReturn(List.of(item1, item2, item3));

        SummaryResponse response = service.getSummary(sessionId);

        assertEquals(sessionId, response.getSessionId());
        assertEquals(3, response.getTotalItems());
        assertNotNull(response.getFirstActionItem());
        assertEquals(item1Id, response.getFirstActionItem().getItemId());
        assertEquals(2, response.getItemsByCategory().get("NOW").size());
        assertEquals(1, response.getItemsByCategory().get("TOMORROW").size());
        assertEquals(0, response.getItemsByCategory().get("DROP").size());
    }

    @Test
    @DisplayName("getReview excludes DROP items")
    void getReview_excludesDropItems() {
        UUID item1Id = UUID.randomUUID();
        UUID item2Id = UUID.randomUUID();
        UUID item3Id = UUID.randomUUID();

        DecompressionItem item1 = createItem(sessionId, item1Id, "NOW");
        item1.setSortOrder(1);
        DecompressionItem item2 = createItem(sessionId, item2Id, "DROP");
        item2.setSortOrder(2);
        DecompressionItem item3 = createItem(sessionId, item3Id, "TOMORROW");
        item3.setSortOrder(3);

        when(sessionMapper.findById(sessionId)).thenReturn(inProgressSession);
        when(itemMapper.findBySessionIdOrderBySortOrder(sessionId)).thenReturn(List.of(item1, item2, item3));

        ReviewResponse response = service.getReview(sessionId);

        assertEquals(2, response.getItems().size());
        assertTrue(response.getItems().stream().noneMatch(i -> "DROP".equals(i.getCategory())));
    }

    @Test
    @DisplayName("updateCategory on completed session: TOMORROW → DROP succeeds")
    void updateCategory_completedSession_toDrop_fromTomorrow_succeeds() {
        DecompressionItem item = createItem(sessionId, itemId, "TOMORROW");
        when(itemMapper.findById(itemId)).thenReturn(item);
        when(sessionMapper.findById(sessionId)).thenReturn(completedSession);

        UpdateCategoryRequest request = new UpdateCategoryRequest("DROP");
        ItemResponse response = service.updateCategory(itemId, request);

        assertEquals("DROP", response.getCategory());
        verify(itemMapper).updateCategory(itemId, "DROP");
    }

    @Test
    @DisplayName("updateCategory on completed session: THIS_WEEK → DROP succeeds")
    void updateCategory_completedSession_toDrop_fromThisWeek_succeeds() {
        DecompressionItem item = createItem(sessionId, itemId, "THIS_WEEK");
        when(itemMapper.findById(itemId)).thenReturn(item);
        when(sessionMapper.findById(sessionId)).thenReturn(completedSession);

        UpdateCategoryRequest request = new UpdateCategoryRequest("DROP");
        ItemResponse response = service.updateCategory(itemId, request);

        assertEquals("DROP", response.getCategory());
        verify(itemMapper).updateCategory(itemId, "DROP");
    }

    @Test
    @DisplayName("updateCategory on completed session: WAITING → DROP succeeds")
    void updateCategory_completedSession_toDrop_fromWaiting_succeeds() {
        DecompressionItem item = createItem(sessionId, itemId, "WAITING");
        when(itemMapper.findById(itemId)).thenReturn(item);
        when(sessionMapper.findById(sessionId)).thenReturn(completedSession);

        UpdateCategoryRequest request = new UpdateCategoryRequest("DROP");
        ItemResponse response = service.updateCategory(itemId, request);

        assertEquals("DROP", response.getCategory());
        verify(itemMapper).updateCategory(itemId, "DROP");
    }

    @Test
    @DisplayName("updateCategory on completed session: MEMO → DROP succeeds")
    void updateCategory_completedSession_toDrop_fromMemo_succeeds() {
        DecompressionItem item = createItem(sessionId, itemId, "MEMO");
        when(itemMapper.findById(itemId)).thenReturn(item);
        when(sessionMapper.findById(sessionId)).thenReturn(completedSession);

        UpdateCategoryRequest request = new UpdateCategoryRequest("DROP");
        ItemResponse response = service.updateCategory(itemId, request);

        assertEquals("DROP", response.getCategory());
        verify(itemMapper).updateCategory(itemId, "DROP");
    }

    @Test
    @DisplayName("updateCategory on completed session: WORRY_ONLY → DROP succeeds")
    void updateCategory_completedSession_toDrop_fromWorryOnly_succeeds() {
        DecompressionItem item = createItem(sessionId, itemId, "WORRY_ONLY");
        when(itemMapper.findById(itemId)).thenReturn(item);
        when(sessionMapper.findById(sessionId)).thenReturn(completedSession);

        UpdateCategoryRequest request = new UpdateCategoryRequest("DROP");
        ItemResponse response = service.updateCategory(itemId, request);

        assertEquals("DROP", response.getCategory());
        verify(itemMapper).updateCategory(itemId, "DROP");
    }

    @Test
    @DisplayName("updateCategory on completed session: TOMORROW → NOW throws SessionAlreadyCompleteException")
    void updateCategory_completedSession_toNow_throwsException() {
        DecompressionItem item = createItem(sessionId, itemId, "TOMORROW");
        when(itemMapper.findById(itemId)).thenReturn(item);
        when(sessionMapper.findById(sessionId)).thenReturn(completedSession);

        UpdateCategoryRequest request = new UpdateCategoryRequest("NOW");

        assertThrows(SessionAlreadyCompleteException.class,
                () -> service.updateCategory(itemId, request));
    }

    @Test
    @DisplayName("updateCategory on completed session: DROP → DROP throws SessionAlreadyCompleteException")
    void updateCategory_completedSession_dropToDrop_throwsException() {
        DecompressionItem item = createItem(sessionId, itemId, "DROP");
        when(itemMapper.findById(itemId)).thenReturn(item);
        when(sessionMapper.findById(sessionId)).thenReturn(completedSession);

        UpdateCategoryRequest request = new UpdateCategoryRequest("DROP");

        assertThrows(SessionAlreadyCompleteException.class,
                () -> service.updateCategory(itemId, request));
    }

    @Test
    @DisplayName("updateCategory on completed session: null category → DROP throws SessionAlreadyCompleteException")
    void updateCategory_completedSession_nullToDrop_throwsException() {
        DecompressionItem item = createItem(sessionId, itemId, null);
        when(itemMapper.findById(itemId)).thenReturn(item);
        when(sessionMapper.findById(sessionId)).thenReturn(completedSession);

        UpdateCategoryRequest request = new UpdateCategoryRequest("DROP");

        assertThrows(SessionAlreadyCompleteException.class,
                () -> service.updateCategory(itemId, request));
    }

    // --- Helper ---

    private DecompressionItem createItem(UUID sessionId, UUID itemId, String category) {
        DecompressionItem item = new DecompressionItem();
        item.setItemId(itemId);
        item.setSessionId(sessionId);
        item.setContent("Test content");
        item.setCategory(category);
        item.setSortOrder(1);
        item.setCreatedAt(OffsetDateTime.now(ZoneOffset.UTC));
        item.setUpdatedAt(OffsetDateTime.now(ZoneOffset.UTC));
        return item;
    }
}
