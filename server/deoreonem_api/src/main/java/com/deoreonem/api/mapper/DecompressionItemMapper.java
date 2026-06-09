package com.deoreonem.api.mapper;

import com.deoreonem.api.domain.DecompressionItem;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.UUID;

@Mapper
public interface DecompressionItemMapper {

    void insertItem(DecompressionItem item);

    DecompressionItem findById(UUID itemId);

    List<DecompressionItem> findBySessionIdOrderBySortOrder(UUID sessionId);

    void updateCategory(@Param("itemId") UUID itemId, @Param("category") String category);

    Integer getMaxSortOrder(UUID sessionId);
}
