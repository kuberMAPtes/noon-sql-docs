use test_db;

SELECT * FROM members;
SELECT * FROM building;
SELECT * FROM feed;
SELECT * FROM zzim;
SELECT * FROM feed_attachment;
SELECT * FROM tag;
SELECT * FROM tag_feed;
SELECT * FROM feed_comment;

# member_1이 좋아요를 누른 피드의 목록
SELECT * FROM zzim WHERE zzim_type = 'LIKE' AND member_id = 'member_1';
SELECT f.* FROM feed f INNER JOIN zzim z ON f.feed_id = z.feed_id WHERE z.zzim_type = 'LIKE' AND z.member_id = 'member_1' AND z.activated = true AND f.activated = true;
# JPQL
# SELECT f FROM Feed f INNER JOIN Zzim z ON f.feedId = z.feed.feedId WHERE z.zzimType = 'LIKE' AND f.writer.memberId = :writerId AND f.activated = true

# member_1이 북마크를 한 피드의 목록
SELECT * FROM zzim WHERE zzim_type = 'BOOKMARK' AND member_id = 'member_1';
SELECT f.* FROM feed f INNER JOIN zzim z ON f.feed_id = z.feed_id WHERE z.zzim_type = 'BOOKMARK' AND z.member_id = 'member_1' AND z.activated = true AND f.activated = true;
# JPQL
# SELECT f FROM Feed f INNER JOIN Zzim z ON f.feedId = z.feedId WHERE z.zzimType = 'BOOKMARK' AND f.writer.memberId = :#{writerId} AND f.activated = true

# member_1이 구독한 건물에 대한 피드 목록
SELECT * FROM zzim WHERE zzim_type = 'SUBSCRIPTION' AND member_id = 'member_1';
SELECT f.* FROM feed f INNER JOIN zzim z ON f.building_id = z.building_id WHERE z.zzim_type = 'SUBSCRIPTION' AND z.member_id = 'member_1' AND z.activated = true AND f.activated = true;
# JPQL
# SELECT f FROM Feed f INNER JOIN Zzim z ON f.building.buildingId = z.buildingId WHERE z.zzimType = 'SUBSCRIPTION' AND z.memberId = :#{#member.memberId} AND f.activated = true AND z.activated = true

