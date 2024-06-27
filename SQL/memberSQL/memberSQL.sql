-- 1. addMember
INSERT INTO members (
    member_id, nickname, phone_number, member_role, dajung_score, signed_off, member_profile_public_range,
    building_subscription_public_range, all_feed_public_range, receiving_all_notification_allowed
) VALUES (
    'member_id_value', 'nickname_value', 'phone_number_value', 'MEMBER', 0, false, 'PUBLIC', 'PUBLIC', 'PUBLIC', true
);
-- 2. addMemberRelationship
SELECT * FROM member_relationships WHERE from_member_id = 'from_member_id_value' AND to_member_id = 'to_member_id_value';
-- 3. findMemberById
INSERT INTO member_relationships (
    from_member_id, to_member_id, activated
) VALUES (
    'from_member_id_value', 'to_member_id_value', true
);
SELECT * FROM members WHERE member_id = 'member_id_value';
-- 4. findMemberByNickname
SELECT * FROM members WHERE nickname = 'nickname_value';
-- 5. findMemberByPhoneNumber
SELECT * FROM members WHERE phone_number = 'phone_number_value';
-- 6. findMemberListByCriteria
SELECT * FROM members WHERE nickname = 'criteria_nickname' AND phone_number = 'criteria_phone_number';
-- 7. findMemberRelationship
SELECT * FROM member_relationships WHERE from_member_id = 'from_member_id_value' AND to_member_id = 'to_member_id_value';
-- 8. findMemberRelationshipListByCriteria
SELECT * FROM member_relationships WHERE relationship_type = 'criteria_relationship_type';
-- 9. updateMember
UPDATE members SET
    nickname = 'new_nickname_value',
    unlock_time = 'new_unlock_time_value',
    profile_photo_url = 'new_profile_photo_url_value',
    profile_intro = 'new_profile_intro_value',
    dajung_score = new_dajung_score_value,
    signed_off = new_signed_off_value,
    building_subscription_public_range = 'new_building_subscription_public_range_value',
    all_feed_public_range = 'new_all_feed_public_range_value',
    member_profile_public_range = 'new_member_profile_public_range_value',
    receiving_all_notification_allowed = new_receiving_all_notification_allowed_value
WHERE member_id = 'member_id_value';
-- 10. updateMemberRelationship
UPDATE member_relationships SET
    relationship_type = 'new_relationship_type_value',
    activated = new_activated_value,
    from_member_id = 'new_from_member_id_value',
    to_member_id = 'new_to_member_id_value'
WHERE from_member_id = 'from_member_id_value' AND to_member_id = 'to_member_id_value';
-- 11. updatePassword
UPDATE members SET pwd = 'new_password_value' WHERE member_id = 'member_id_value';
-- 12. updatePhoneNumber
UPDATE members SET phone_number = 'new_phone_number_value' WHERE member_id = 'member_id_value';
-- 13. updateMemberProfilePhoto
UPDATE members SET profile_photo_url = 'new_profile_photo_url_value' WHERE member_id = 'member_id_value';
-- 14. deleteMemberRelationship
DELETE FROM member_relationships WHERE from_member_id = 'from_member_id_value' AND to_member_id = 'to_member_id_value';
-- 15. deleteMember
DELETE FROM members WHERE member_id = 'member_id_value';







