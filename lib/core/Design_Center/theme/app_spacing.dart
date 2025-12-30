import 'package:flutter/material.dart';


/// Centralize component spacing for consistent padding and gaps
/// Usage: Padding(padding: AppSpacing.cardPadding)
class AppSpacing {
  // --- BUTTON SPACING ---
  /// Small button padding (12px H, 8px V)
  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 8.0,
  );

  /// Medium button padding (16px H, 12px V)
  static const EdgeInsets buttonPaddingMedium = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );

  /// Standard button padding (24px H, 14px V)
  static const EdgeInsets buttonPaddingStandard = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 14.0,
  );

  /// Large button padding (24px H, 16px V)
  static const EdgeInsets buttonPaddingLarge = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 16.0,
  );

  // --- CARD SPACING ---
  /// Standard card padding (16px)
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);

  /// Default card padding (alias for cardPadding)
  static const EdgeInsets cardPaddingDefault = cardPadding;

  /// Compact card padding (12px)
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(12.0);

  /// Large card padding (24px)
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(24.0);

  // --- LIST ITEM SPACING ---
  /// Standard list item padding (16px H, 12px V)
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );

  /// Compact list item padding (12px H, 8px V)
  static const EdgeInsets listItemPaddingCompact = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 8.0,
  );

  /// Large list item padding (20px H, 16px V)
  static const EdgeInsets listItemPaddingLarge = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );

  // --- DIALOG/SHEET SPACING ---
  /// Dialog padding (24px)
  static const EdgeInsets dialogPadding = EdgeInsets.all(24.0);

  /// Sheet padding (16px)
  static const EdgeInsets sheetPadding = EdgeInsets.all(16.0);

  /// Sheet header padding (24px top & horizontal, 16px bottom)
  static const EdgeInsets sheetHeaderPadding = EdgeInsets.fromLTRB(24, 24, 24, 16);

  // --- SCREEN/PAGE SPACING ---
  /// Screen padding (16px)
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);

  /// Screen horizontal padding (16px)
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: 16.0);

  /// Screen vertical padding (16px)
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(vertical: 16.0);


  /// Icon padding standard (8px)
  /// Icon padding standard (8px)
  static const EdgeInsets iconPaddingStandard = EdgeInsets.all(8.0);

  /// Standard padding all around (16px)
  static const EdgeInsets paddingAll16 = EdgeInsets.all(16.0);

  // --- ICON BUTTON SPACING ---
  /// Icon button padding (8px)
  static const EdgeInsets iconButtonPadding = EdgeInsets.all(8.0);

  // --- VERTICAL GAPS/SPACING ---
  /// Extra small gap (4px)
  static const SizedBox gapXSmall = SizedBox(height: 4.0);
  static const SizedBox gapXs = gapXSmall;

  /// Small gap (8px)
  static const SizedBox gapSmall = SizedBox(height: 8.0);
  static const SizedBox gapS = gapSmall;

  /// Medium-small gap (12px)
  static const SizedBox gapMediumSmall = SizedBox(height: 12.0);
  static const SizedBox gap12 = gapMediumSmall;

  /// Medium gap (16px)
  static const SizedBox gapMedium = SizedBox(height: 16.0);
  static const SizedBox gapM = gapMedium;

  /// Large gap (24px)
  static const SizedBox gapLarge = SizedBox(height: 24.0);
  static const SizedBox gapL = gapLarge;

  /// Extra large gap (32px)
  static const SizedBox gapXLarge = SizedBox(height: 32.0);
  static const SizedBox gapXl = gapXLarge;

  /// XXL gap (48px) - for major section spacing
  static const SizedBox gapXXLarge = SizedBox(height: 48.0);
  static const SizedBox gapXxl = gapXXLarge;

  // --- HORIZONTAL GAPS/SPACING ---
  /// Extra small horizontal gap (4px)
  static const SizedBox gapHorizontalXSmall = SizedBox(width: 4.0);

  /// Small horizontal gap (8px)
  static const SizedBox gapHorizontalSmall = SizedBox(width: 8.0);

  /// Medium-small horizontal gap (12px)
  static const SizedBox gapHorizontalMediumSmall = SizedBox(width: 12.0);
  static const SizedBox gapH12 = gapHorizontalMediumSmall;

  /// Medium horizontal gap (16px)
  static const SizedBox gapHorizontalMedium = SizedBox(width: 16.0);

  /// Large horizontal gap (24px)
  static const SizedBox gapHorizontalLarge = SizedBox(width: 24.0);

  /// Extra large horizontal gap (32px)
  static const SizedBox gapHorizontalXLarge = SizedBox(width: 32.0);

  /// XXL horizontal gap (48px) - for major section spacing
  static const SizedBox gapHorizontalXXLarge = SizedBox(width: 48.0);
  static const SizedBox gapHXxl = gapHorizontalXXLarge;

  // --- DIVIDER SPACING ---

  // --- DIALOG SPACING ---
  /// Dialog inset padding (24px H, 40px V)
  static const EdgeInsets dialogInsetPaddingDefault = EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0);

  /// Dialog content padding (24px)
  static const EdgeInsets dialogPaddingDefault = EdgeInsets.all(24.0);

  // --- APP BAR SPACING ---
  /// App bar margin (16px H, 8px V)
  static const EdgeInsets appBarMarginDefault = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);

  /// App bar padding (16px H)
  static const EdgeInsets appBarPaddingDefault = EdgeInsets.symmetric(horizontal: 16.0);

  // --- TILE SPACING ---
  /// Default tile padding (8px H, 16px V)
  static const EdgeInsets tilePaddingDefault = EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0);

  /// Expansion tile padding (16px H, 12px V)
  static const EdgeInsets expansionTilePaddingDefault = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

  // --- EMPTY STATE SPACING ---
  /// Empty state padding (32px)
  static const EdgeInsets emptyStatePaddingDefault = EdgeInsets.all(32.0);

  /// Empty state icon padding (16px bottom)
  static const EdgeInsets emptyStateIconPaddingDefault = EdgeInsets.only(bottom: 16.0);

  // --- SETTINGS SPACING ---
  /// Settings header padding (24px H, 16px top)
  static const EdgeInsets settingsHeaderPaddingDefault = EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0);

  /// Tab bar view padding (16px H, 16px top)
  static const EdgeInsets tabBarViewPaddingDefault = EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0);

  // --- CHART SPACING ---
  /// Chart header padding (16px H, 12px V)
  static const EdgeInsets chartHeaderPaddingDefault = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

  // --- NAVIGATION BAR SPACING ---
  /// Navigation bar margin (16px H, 24px bottom)
  static const EdgeInsets navBarMargin = EdgeInsets.fromLTRB(16.0, 0, 16.0, 24.0);

  /// Navigation bar horizontal margin (16px)
  static const double navBarMarginHorizontal = 16.0;

  /// Navigation bar bottom margin (24px)
  static const double navBarMarginBottom = 24.0;

  /// Navigation bar padding bottom (90px)
  static const EdgeInsets navBarPaddingBottom = EdgeInsets.only(bottom: 90.0);

  // --- DIVIDER SPACING ---
  /// Divider with standard padding (16px horizontal)
  static const EdgeInsets dividerPadding = EdgeInsets.symmetric(horizontal: 16.0);

  /// Divider with large padding (24px horizontal)
  static const EdgeInsets dividerPaddingLarge = EdgeInsets.symmetric(horizontal: 24.0);

  // --- CONTENT SPACING ---
  /// Overview header padding (16px H from L/R, 12px top)
  static const EdgeInsets overviewHeaderPaddingDefault = EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0);

  /// Content horizontal padding (16px H)
  static const EdgeInsets contentHorizontalPaddingDefault = EdgeInsets.symmetric(horizontal: 16.0);

  /// Section title padding (24px V)
  static const EdgeInsets sectionTitlePaddingDefault = EdgeInsets.symmetric(vertical: 24.0);

  /// Portfolio header padding (16px)
  static const EdgeInsets headerPaddingDefault = EdgeInsets.all(16.0);

  /// Asset list item margin (16px H, 6px V)
  static const EdgeInsets assetListItemMargin = EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0);

  /// Asset list item padding (16px)
  static const EdgeInsets assetListItemPadding = EdgeInsets.all(16.0);

  /// Chip padding default (6px H)
  static const EdgeInsets chipPaddingDefault = EdgeInsets.symmetric(horizontal: 6.0);

  // --- WIZARD/FORM SPECIFIC SPACING ---
  /// Wizard step button padding (24px H, 12px V)
  static const EdgeInsets wizardStepPadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
  
  /// Form field padding (16px H, 10px V)
  static const EdgeInsets formFieldPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0);
  
  /// Compact chip padding (6px H, 2px V)
  static const EdgeInsets chipPaddingCompact = EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0);
  
  /// Modal header padding with large horizontal (40px H)
  static const EdgeInsets modalHeaderPadding = EdgeInsets.symmetric(horizontal: 40.0);
  
  /// Bottom sheet custom padding (24px L/R, 12px top, 48px bottom)
  static const EdgeInsets bottomSheetPaddingCustom = EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 48.0);

  /// Asset card header padding (16px)
  static const EdgeInsets assetCardHeaderPaddingDefault = EdgeInsets.all(16.0);
  
  // --- SPECIAL SIZED BOXES (for specific needs) ---
  /// Tiny gap (2px height) - minimal spacing
  static const SizedBox gapTiny = SizedBox(height: 2.0);
  
  /// Micro horizontal gap (2px width)
  static const SizedBox gapHTiny = SizedBox(width: 2.0);
  
  /// Gap 4 horizontal
  static const SizedBox gapH4 = SizedBox(width: 4.0);
  
  /// Gap 6 horizontal
  static const SizedBox gapH6 = SizedBox(width: 6.0);
  
  /// Gap 10 horizontal
  static const SizedBox gapH10 = SizedBox(width: 10.0);
  
  /// Gap 20 vertical (between M and L)
  static const SizedBox gap20 = SizedBox(height: 20.0);
  
  /// Gap 40 vertical (large section spacing)
  static const SizedBox gap40 = SizedBox(height: 40.0);
  
  /// Gap 90 vertical (navigation bar clearance)
  static const SizedBox gap90 = SizedBox(height: 90.0);
  
  /// Gap 100 vertical (full section spacing)
  static const SizedBox gap100 = SizedBox(height: 100.0);
  
  /// Special sized box for circular progress (10x10)
  static const SizedBox progressSmall = SizedBox(width: 10.0, height: 10.0);
}
