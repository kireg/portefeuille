Voici l'architecture du dossier `lib`:
```
lib
  ├── core
  │   ├── data
  │   │   ├── abstractions
  │   │   │   └── i_settings.dart
  │   │   ├── models
  │   │   │   ├── account.dart
  │   │   │   ├── account_type.dart
  │   │   │   ├── aggregated_asset.dart
  │   │   │   ├── aggregated_portfolio_data.dart
  │   │   │   ├── app_data_backup.dart
  │   │   │   ├── asset.dart
  │   │   │   ├── asset_metadata.dart
  │   │   │   ├── asset_type.dart
  │   │   │   ├── exchange_rate_history.dart
  │   │   │   ├── institution.dart
  │   │   │   ├── portfolio.dart
  │   │   │   ├── portfolio_value_history_point.dart
  │   │   │   ├── price_history_point.dart
  │   │   │   ├── projection_data.dart
  │   │   │   ├── savings_plan.dart
  │   │   │   ├── sync_log.dart
  │   │   │   ├── sync_status.dart
  │   │   │   ├── transaction.dart
  │   │   │   ├── transaction_type.dart
  │   │   ├── repositories
  │   │   │   ├── portfolio_repository.dart
  │   │   │   └── settings_repository.dart
  │   │   └── services
  │   │       ├── api_service.dart
  │   │       ├── backup_service.dart
  │   │       └── sync_log_export_service.dart
  │   ├── ui
  │   │   ├── theme
  │   │   │   ├── app_colors.dart
  │   │   │   ├── app_dimens.dart
  │   │   │   ├── app_theme.dart
  │   │   │   └── app_typography.dart
  │   │   ├── widgets
  │   │   │   ├── components
  │   │   │   │   ├── app_animated_background.dart
  │   │   │   │   ├── app_floating_nav_bar.dart
  │   │   │   │   ├── app_screen.dart
  │   │   │   │   └── app_tile.dart
  │   │   │   ├── inputs
  │   │   │   │   ├── app_dropdown.dart
  │   │   │   │   └── app_text_field.dart
  │   │   │   ├── primitives
  │   │   │   │   ├── app_animated_value.dart
  │   │   │   │   ├── app_button.dart
  │   │   │   │   ├── app_card.dart
  │   │   │   │   └── app_icon.dart
  │   │   │   ├── account_type_chip.dart
  │   │   │   ├── asset_list_item.dart
  │   │   │   ├── fade_in_slide.dart
  │   │   │   ├── portfolio_header.dart
  │   │   │   └── transaction_list_item.dart
  │   │   └── splash_screen.dart
  │   └── utils
  │       ├── constants.dart
  │       ├── currency_formatter.dart
  │       ├── enum_helpers.dart
  │       └── isin_validator.dart
  ├── features
  │   ├── 00_app
  │   │   ├── models
  │   │   │   └── background_activity.dart
  │   │   ├── providers
  │   │   │   ├── portfolio_provider.dart
  │   │   │   └── settings_provider.dart
  │   │   ├── services
  │   │   │   ├── calculation_service.dart
  │   │   │   ├── demo_data_service.dart
  │   │   │   ├── hydration_service.dart
  │   │   │   ├── migration_service.dart
  │   │   │   ├── modal_service.dart
  │   │   │   ├── route_manager.dart
  │   │   │   ├── sync_service.dart
  │   │   │   └── transaction_service.dart
  │   │   ├── README.md
  │   │   └── main.dart
  │   ├── 01_launch
  │   │   ├── data
  │   │   │   └── wizard_models.dart
  │   │   ├── ui
  │   │   │   ├── providers
  │   │   │   │   └── setup_wizard_provider.dart
  │   │   │   ├── widgets
  │   │   │   │   ├── wizard_dialogs
  │   │   │   │   │   ├── add_account_dialog.dart
  │   │   │   │   │   └── add_asset_dialog.dart
  │   │   │   │   └── initial_setup_wizard.dart
  │   │   │   ├── launch_screen.dart
  │   │   │   └── splash_screen.dart
  │   │   └── README.md
  │   ├── 02_dashboard
  │   │   ├── ui
  │   │   │   ├── widgets
  │   │   │   │   └── dashboard_app_bar.dart
  │   │   │   └── dashboard_screen.dart
  │   │   └── README.md
  │   ├── 03_overview
  │   │   ├── ui
  │   │   │   ├── widgets
  │   │   │   │   ├── account_tile.dart
  │   │   │   │   ├── ai_analysis_card.dart
  │   │   │   │   ├── allocation_chart.dart
  │   │   │   │   ├── asset_list_item.dart
  │   │   │   │   ├── asset_type_allocation_chart.dart
  │   │   │   │   ├── institution_tile.dart
  │   │   │   │   ├── portfolio_header.dart
  │   │   │   │   ├── portfolio_history_chart.dart
  │   │   │   │   └── sync_alerts_card.dart
  │   │   │   └── overview_tab.dart
  │   │   └── README.md
  │   ├── 04_journal
  │   │   ├── ui
  │   │   │   ├── dialogs
  │   │   │   │   └── asset_dialogs.dart
  │   │   │   ├── views
  │   │   │   │   ├── synthese_view.dart
  │   │   │   │   └── transactions_view.dart
  │   │   │   └── widgets
  │   │   │       ├── asset_card.dart
  │   │   │       ├── summary_empty_state.dart
  │   │   │       └── transaction_list_item.dart
  │   │   └── README.md
  │   ├── 05_planner
  │   │   └── ui
  │   │       ├── widgets
  │   │       │   ├── projection_chart.dart
  │   │       │   ├── projection_section.dart
  │   │       │   └── savings_plans_section.dart
  │   │       └── planner_tab.dart
  │   ├── 06_settings
  │   │   ├── ui
  │   │   │   ├── widgets
  │   │   │   │   ├── app_settings.dart
  │   │   │   │   ├── appearance_card.dart
  │   │   │   │   ├── appearance_settings.dart
  │   │   │   │   ├── backup_card.dart
  │   │   │   │   ├── danger_zone_card.dart
  │   │   │   │   ├── general_settings_card.dart
  │   │   │   │   ├── online_mode_card.dart
  │   │   │   │   ├── portfolio_card.dart
  │   │   │   │   ├── portfolio_management_settings.dart
  │   │   │   │   ├── reset_app_section.dart
  │   │   │   │   └── sync_logs_card.dart
  │   │   │   └── settings_screen.dart
  │   │   └── README.md
  │   ├── 07_management
  │   │   ├── ui
  │   │   │   ├── providers
  │   │   │   │   └── transaction_form_state.dart
  │   │   │   ├── screens
  │   │   │   │   ├── add_account_screen.dart
  │   │   │   │   ├── add_institution_screen.dart
  │   │   │   │   ├── add_savings_plan_screen.dart
  │   │   │   │   ├── add_transaction_screen.dart
  │   │   │   │   └── edit_transaction_screen.dart
  │   │   │   └── widgets
  │   │   │       ├── form_sections
  │   │   │       │   ├── _account_selector.dart
  │   │   │       │   ├── _asset_fields.dart
  │   │   │       │   ├── _cash_fields.dart
  │   │   │       │   ├── _common_fields.dart
  │   │   │       │   ├── _dividend_fields.dart
  │   │   │       │   ├── _dynamic_fields.dart
  │   │   │       │   ├── _form_header.dart
  │   │   │       │   └── _type_selector.dart
  │   │   │       └── transaction_form_body.dart
  │   │   └── README.md
  │   └── 08_reports
  │       └── README.md
  ├── test
  │   └── test_harness.dart
  └── main.dart
```


--- FIN DU CONTEXTE ---

