CREATE TABLE `backlog_elements` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_story` varchar(255) DEFAULT NULL,
  `description` text,
  `estimate` decimal(5,1) DEFAULT NULL,
  `created_on` datetime DEFAULT NULL,
  `sprint_id` int(10) DEFAULT NULL,
  `position` int(10) DEFAULT NULL,
  `project_id` int(10) NOT NULL,
  `position_in_sprint` int(10) DEFAULT NULL,
  `domain_id` int(10) NOT NULL,
  `locked_by_id` int(10) DEFAULT NULL,
  `type` varchar(255) NOT NULL DEFAULT 'Item',
  PRIMARY KEY (`id`),
  KEY `index_backlog_items_on_position_in_sprint` (`position_in_sprint`),
  KEY `index_backlog_items_on_position` (`position`),
  KEY `domain_id` (`domain_id`),
  KEY `project_id` (`project_id`),
  KEY `sprint_id` (`sprint_id`),
  CONSTRAINT `backlog_elements_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `backlog_elements_ibfk_2` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `backlog_elements_ibfk_3` FOREIGN KEY (`sprint_id`) REFERENCES `sprints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `clips` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_id` int(10) NOT NULL,
  `item_id` int(10) DEFAULT NULL,
  `content_file_name` varchar(255) DEFAULT NULL,
  `content_content_type` varchar(255) DEFAULT NULL,
  `content_file_size` int(10) DEFAULT NULL,
  `content_updated_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `domain_id` (`domain_id`),
  KEY `backlog_item_id` (`item_id`),
  CONSTRAINT `clips_ibfk_2` FOREIGN KEY (`item_id`) REFERENCES `backlog_elements` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `clips_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `comments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `item_id` int(10) DEFAULT NULL,
  `user_id` int(10) NOT NULL,
  `text` text NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `domain_id` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `domain_id` (`domain_id`),
  KEY `backlog_item_id` (`item_id`),
  CONSTRAINT `comments_ibfk_4` FOREIGN KEY (`item_id`) REFERENCES `backlog_elements` (`id`) ON DELETE CASCADE,
  CONSTRAINT `comments_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `comments_ibfk_3` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `customers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(64) DEFAULT NULL,
  `last_name` varchar(64) DEFAULT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(64) DEFAULT NULL,
  `nip` varchar(255) DEFAULT NULL,
  `country` varchar(255) NOT NULL,
  `state` varchar(255) DEFAULT NULL,
  `city` varchar(255) NOT NULL,
  `postcode` varchar(255) NOT NULL,
  `street` varchar(255) NOT NULL,
  `street_n1` varchar(8) DEFAULT NULL,
  `street_n2` varchar(8) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `company_name` varchar(255) DEFAULT NULL,
  `company` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `delete_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_id` int(10) NOT NULL,
  `user_id` int(10) NOT NULL,
  `key` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_delete_requests_on_key` (`key`),
  KEY `domain_id` (`domain_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `delete_requests_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE,
  CONSTRAINT `delete_requests_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `domains` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `full_name` varchar(40) DEFAULT NULL,
  `plan_id` int(10) NOT NULL,
  `billing_start_date` date DEFAULT NULL,
  `free_months` int(10) NOT NULL DEFAULT '0',
  `debtor` tinyint(1) DEFAULT '0',
  `heard_about_us` varchar(255) DEFAULT NULL,
  `first_payment_status` int(10) DEFAULT NULL,
  `customer_id` int(10) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_domains_on_name` (`name`),
  UNIQUE KEY `index_domains_on_customer_id` (`customer_id`),
  CONSTRAINT `domains_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `impediment_actions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `open_after` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_impediment_actions_on_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `impediment_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `impediment_id` int(10) NOT NULL,
  `impediment_action_id` int(10) NOT NULL,
  `user_id` int(10) NOT NULL,
  `comment` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `domain_id` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `impediment_action_id` (`impediment_action_id`),
  KEY `user_id` (`user_id`),
  KEY `domain_id` (`domain_id`),
  KEY `impediment_id` (`impediment_id`),
  CONSTRAINT `impediment_logs_ibfk_5` FOREIGN KEY (`impediment_id`) REFERENCES `impediments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `impediment_logs_ibfk_2` FOREIGN KEY (`impediment_action_id`) REFERENCES `impediment_actions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `impediment_logs_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `impediment_logs_ibfk_4` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `impediments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `summary` varchar(255) NOT NULL,
  `description` text,
  `project_id` int(10) NOT NULL,
  `is_open` tinyint(1) DEFAULT NULL,
  `domain_id` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `domain_id` (`domain_id`),
  KEY `project_id` (`project_id`),
  CONSTRAINT `impediments_ibfk_3` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `impediments_ibfk_2` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `invoice_number_sequencers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `month` varchar(255) NOT NULL,
  `year` varchar(255) NOT NULL,
  `number` int(10) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_invoice_number_sequencers_on_year_and_month` (`year`,`month`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `invoices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_id` int(10) DEFAULT NULL,
  `invoice_number` varchar(255) NOT NULL,
  `issue_date` date NOT NULL,
  `invoice_type` varchar(8) DEFAULT NULL,
  `customer_id` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `domain_id` (`domain_id`),
  KEY `customer_id` (`customer_id`),
  CONSTRAINT `invoices_ibfk_2` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`),
  CONSTRAINT `invoices_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `item_tags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tag_id` int(10) NOT NULL,
  `item_id` int(10) DEFAULT NULL,
  `domain_id` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_backlog_item_tags_on_tag_id_and_backlog_item_id` (`tag_id`,`item_id`),
  KEY `backlog_item_id` (`item_id`),
  KEY `domain_id` (`domain_id`),
  CONSTRAINT `item_tags_ibfk_4` FOREIGN KEY (`item_id`) REFERENCES `backlog_elements` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `item_tags_ibfk_1` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `item_tags_ibfk_3` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `juggernaut_sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_id` int(10) NOT NULL,
  `user_id` int(10) NOT NULL,
  `subscribed_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `project_id` int(10) NOT NULL,
  `initial_message_id` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `project_id` (`project_id`),
  KEY `domain_id` (`domain_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `juggernaut_sessions_ibfk_5` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `juggernaut_sessions_ibfk_3` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `juggernaut_sessions_ibfk_4` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `licenses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_id` int(10) NOT NULL,
  `entity_name` varchar(255) NOT NULL,
  `key` text NOT NULL,
  `valid_to` date DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `domain_id` (`domain_id`),
  CONSTRAINT `licenses_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `log_fields` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `log_id` int(10) NOT NULL,
  `domain_id` int(10) NOT NULL,
  `name` varchar(255) NOT NULL,
  `old_value` varchar(255) DEFAULT NULL,
  `new_value` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `log_id` (`log_id`),
  KEY `domain_id` (`domain_id`),
  CONSTRAINT `log_fields_ibfk_2` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE,
  CONSTRAINT `log_fields_ibfk_1` FOREIGN KEY (`log_id`) REFERENCES `logs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_id` int(10) NOT NULL,
  `sprint_id` int(10) DEFAULT NULL,
  `item_id` int(10) DEFAULT NULL,
  `task_id` int(10) DEFAULT NULL,
  `action` varchar(8) NOT NULL DEFAULT 'update',
  `logable_type` varchar(16) NOT NULL,
  `task_user_id` int(10) DEFAULT NULL,
  `user_id` int(10) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `domain_id` (`domain_id`),
  KEY `sprint_id` (`sprint_id`),
  KEY `item_id` (`item_id`),
  KEY `index_logs_on_action` (`action`),
  KEY `index_logs_on_logable_type` (`logable_type`),
  KEY `user_id` (`user_id`),
  KEY `task_user_id` (`task_user_id`),
  CONSTRAINT `logs_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `logs_ibfk_2` FOREIGN KEY (`sprint_id`) REFERENCES `sprints` (`id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `logs_ibfk_3` FOREIGN KEY (`item_id`) REFERENCES `backlog_elements` (`id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `logs_ibfk_6` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `logs_ibfk_7` FOREIGN KEY (`task_user_id`) REFERENCES `task_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `news` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `text` text NOT NULL,
  `created_at` datetime NOT NULL,
  `expiration_date` datetime NOT NULL,
  `read_count` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `payments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_id` int(10) DEFAULT NULL,
  `amount` decimal(15,2) NOT NULL,
  `status` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `issue_date` date NOT NULL,
  `from_date` date NOT NULL,
  `to_date` date NOT NULL,
  `plan_id` int(10) DEFAULT NULL,
  `invoice_id` int(10) DEFAULT NULL,
  `customer_id` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `plan_id` (`plan_id`),
  KEY `invoice_id` (`invoice_id`),
  KEY `domain_id` (`domain_id`),
  KEY `customer_id` (`customer_id`),
  CONSTRAINT `payments_ibfk_5` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`),
  CONSTRAINT `payments_ibfk_2` FOREIGN KEY (`plan_id`) REFERENCES `plans` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `payments_ibfk_3` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`) ON DELETE SET NULL,
  CONSTRAINT `payments_ibfk_4` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `plan_changes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_id` int(10) DEFAULT NULL,
  `old_plan_id` int(10) NOT NULL,
  `new_plan_id` int(10) NOT NULL,
  `user_id` int(10) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `customer_id` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `domain_id` (`domain_id`),
  KEY `old_plan_id` (`old_plan_id`),
  KEY `new_plan_id` (`new_plan_id`),
  KEY `user_id` (`user_id`),
  KEY `customer_id` (`customer_id`),
  CONSTRAINT `plan_changes_ibfk_6` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `plan_changes_ibfk_2` FOREIGN KEY (`old_plan_id`) REFERENCES `plans` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `plan_changes_ibfk_3` FOREIGN KEY (`new_plan_id`) REFERENCES `plans` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `plan_changes_ibfk_4` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `plan_changes_ibfk_5` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `plans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `users_limit` int(10) DEFAULT NULL,
  `projects_limit` int(10) DEFAULT NULL,
  `mbytes_limit` int(10) DEFAULT NULL,
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `price` decimal(15,2) DEFAULT NULL,
  `ssl` tinyint(1) NOT NULL DEFAULT '0',
  `public` tinyint(1) NOT NULL DEFAULT '1',
  `timeline_view` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_plans_on_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `projects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `presentation_name` varchar(255) NOT NULL,
  `domain_id` int(10) NOT NULL,
  `calendar_key` varchar(255) DEFAULT NULL,
  `archived` tinyint(1) NOT NULL DEFAULT '0',
  `sprint_length` int(10) NOT NULL DEFAULT '14',
  `backlog_unit` varchar(255) NOT NULL DEFAULT 'SP',
  `task_unit` varchar(255) NOT NULL DEFAULT 'h',
  `time_zone` varchar(255) DEFAULT NULL,
  `free_days` text,
  `csv_separator` varchar(255) NOT NULL DEFAULT ',',
  `estimate_sequence` varchar(255) DEFAULT ',0,0.5,1,2,3,5,8,13,20,40,100,9999',
  `visible_graphs` text,
  `can_edit_finished_sprints` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_projects_on_name_and_domain_id` (`name`,`domain_id`),
  KEY `domain_id` (`domain_id`),
  CONSTRAINT `projects_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `role_assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) NOT NULL,
  `project_id` int(10) NOT NULL,
  `role_id` int(10) NOT NULL,
  `domain_id` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_role_assignments_on_user_id_and_project_id_and_role_id` (`user_id`,`project_id`,`role_id`),
  KEY `project_id` (`project_id`),
  KEY `role_id` (`role_id`),
  KEY `domain_id` (`domain_id`),
  CONSTRAINT `role_assignments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `role_assignments_ibfk_2` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `role_assignments_ibfk_3` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `role_assignments_ibfk_4` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `sprints` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `goals` text,
  `from_date` date DEFAULT NULL,
  `to_date` date DEFAULT NULL,
  `project_id` int(10) NOT NULL,
  `sequence_number` int(10) DEFAULT NULL,
  `domain_id` int(10) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `domain_id` (`domain_id`),
  KEY `project_id` (`project_id`),
  CONSTRAINT `sprints_ibfk_2` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sprints_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `stat_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `stat_run_id` int(10) NOT NULL,
  `kind` varchar(255) NOT NULL,
  `value` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `stat_run_id` (`stat_run_id`),
  CONSTRAINT `stat_data_ibfk_1` FOREIGN KEY (`stat_run_id`) REFERENCES `stat_runs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `stat_runs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `timestamp` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `tags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `project_id` int(10) NOT NULL,
  `domain_id` int(10) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_tags_on_name_and_project_id` (`name`,`project_id`),
  KEY `project_id` (`project_id`),
  KEY `domain_id` (`domain_id`),
  CONSTRAINT `tags_ibfk_1` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `tags_ibfk_2` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `task_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `task_id` int(10) DEFAULT NULL,
  `estimate_new` int(10) DEFAULT NULL,
  `timestamp` datetime DEFAULT NULL,
  `user_id` int(10) DEFAULT NULL,
  `estimate_old` int(10) DEFAULT NULL,
  `sprint_id` int(10) NOT NULL,
  `domain_id` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `task_logs_task_fk` (`task_id`),
  KEY `task_logs_user_fk` (`user_id`),
  KEY `domain_id` (`domain_id`),
  KEY `sprint_id` (`sprint_id`),
  CONSTRAINT `task_logs_ibfk_2` FOREIGN KEY (`sprint_id`) REFERENCES `sprints` (`id`) ON DELETE CASCADE,
  CONSTRAINT `task_logs_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `task_logs_user_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `task_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_id` int(10) NOT NULL,
  `user_id` int(10) NOT NULL,
  `task_id` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_task_users_on_user_id_and_task_id` (`user_id`,`task_id`),
  KEY `domain_id` (`domain_id`),
  KEY `task_id` (`task_id`),
  CONSTRAINT `task_users_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `task_users_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `task_users_ibfk_3` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `tasks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `item_id` int(10) DEFAULT NULL,
  `summary` varchar(255) DEFAULT NULL,
  `estimate` int(10) DEFAULT NULL,
  `created_on` datetime DEFAULT NULL,
  `position` int(10) DEFAULT NULL,
  `domain_id` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `domain_id` (`domain_id`),
  KEY `backlog_item_id` (`item_id`),
  CONSTRAINT `tasks_ibfk_2` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `tasks_ibfk_5` FOREIGN KEY (`item_id`) REFERENCES `backlog_elements` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `themes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `margin_background` varchar(255) DEFAULT NULL,
  `content_background` varchar(255) DEFAULT NULL,
  `buttons_background` varchar(255) DEFAULT NULL,
  `info_box_header_background` varchar(255) DEFAULT NULL,
  `inplace_hover_background` varchar(255) DEFAULT NULL,
  `item_background` varchar(255) DEFAULT NULL,
  `item_description_background` varchar(255) DEFAULT NULL,
  `task_even_background` varchar(255) DEFAULT NULL,
  `task_odd_background` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `user_activations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) NOT NULL,
  `key` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `reset_pwd` tinyint(1) DEFAULT NULL,
  `domain_id` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_user_activations_on_key` (`key`),
  KEY `user_id` (`user_id`),
  KEY `domain_id` (`domain_id`),
  CONSTRAINT `user_activations_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `user_activations_ibfk_2` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `login` varchar(40) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `first_name` varchar(255) NOT NULL,
  `last_name` varchar(255) NOT NULL,
  `email_address` varchar(255) NOT NULL,
  `password` varchar(255) DEFAULT NULL,
  `salt` varchar(255) DEFAULT NULL,
  `active_project_id` int(10) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `domain_id` int(10) NOT NULL,
  `new_offers` tinyint(1) DEFAULT '0',
  `service_updates` tinyint(1) DEFAULT '0',
  `terms_of_use` tinyint(1) DEFAULT '0',
  `active` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `last_news_read_date` datetime DEFAULT NULL,
  `blocked` tinyint(1) NOT NULL,
  `last_login` datetime DEFAULT NULL,
  `theme_id` int(10) DEFAULT NULL,
  `like_spam` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_users_on_login_and_domain_id` (`login`,`domain_id`),
  KEY `users_sprint_id_fk` (`active_project_id`),
  KEY `domain_id` (`domain_id`),
  KEY `theme_id` (`theme_id`),
  CONSTRAINT `users_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `users_ibfk_2` FOREIGN KEY (`theme_id`) REFERENCES `themes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `users_sprint_id_fk` FOREIGN KEY (`active_project_id`) REFERENCES `projects` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
