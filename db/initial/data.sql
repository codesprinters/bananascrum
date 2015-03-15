INSERT INTO `roles` (`id`, `name`, `description`, `code`) VALUES (1, 'Scrum Master', 'Scrum Master', 'scrum_master'), (2, 'Product Owner', 'Product Owner', 'product_owner'), (3, 'Team Member', 'Team Member', 'team_member');

INSERT INTO `impediment_actions` (`id`, `name`, `open_after`) VALUES (1, 'created', 1), (2, 'closed', 0), (3, 'reopened', 1), (4, 'commented', NULL);

INSERT INTO `plans` (`id`, `name`, `users_limit`, `projects_limit`, `mbytes_limit`, `valid_from`, `valid_to`, `price`, `ssl`, `public`, `timeline_view`) VALUES (1, 'No limits', NULL, NULL, NULL, '2009-10-12', NULL, NULL, 0, 1, 1), (2, 'No limits SSL', NULL, NULL, NULL, '2009-10-14', NULL, NULL, 1, 1, 1);

INSERT INTO `domains` (`id`, `name`, `full_name`, `plan_id`, `billing_start_date`, `free_months`, `debtor`, `heard_about_us`, `first_payment_status`) VALUES (1, 'bananascrum', 'Banana Scrum', 1, NULL, 0, 0, NULL, NULL);

INSERT INTO `themes` (`id`, `name`, `slug`, `margin_background`, `content_background`, `buttons_background`, `info_box_header_background`, `inplace_hover_background`, `item_background`, `item_description_background`, `task_even_background`, `task_odd_background`) VALUES (506907317,'Blue','blue','#728FD1','#BEC9E3','#F4DF63','#9EABCA','#FFFFB9','#C9D4F0','#CED9B8','#B8C1CC','#B1BEDC');