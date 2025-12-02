enum BudgetRenewalType { daily, weekly, monthly, yearly, never, custom }

class BudgetRenewalOption {
  const BudgetRenewalOption({required this.type, required this.label, required this.minutes});

  final BudgetRenewalType type;
  final String label;
  final int minutes;
}

const List<BudgetRenewalOption> presetBudgetRenewalOptions = <BudgetRenewalOption>[
  BudgetRenewalOption(type: BudgetRenewalType.daily, label: 'Daily', minutes: 1440),
  BudgetRenewalOption(type: BudgetRenewalType.weekly, label: 'Weekly', minutes: 10080),
  BudgetRenewalOption(type: BudgetRenewalType.monthly, label: 'Monthly', minutes: 43200),
  BudgetRenewalOption(type: BudgetRenewalType.yearly, label: 'Yearly', minutes: 525600),
  BudgetRenewalOption(type: BudgetRenewalType.never, label: 'Never', minutes: 0),
];

enum BudgetAmountOption { tenK, hundredK, oneM, unlimited, custom }

class BudgetAmountOptionData {
  const BudgetAmountOptionData({required this.type, required this.label, this.sats});

  final BudgetAmountOption type;
  final String label;
  final int? sats; // null for unlimited
}

const List<BudgetAmountOptionData> presetBudgetAmountOptions = <BudgetAmountOptionData>[
  BudgetAmountOptionData(type: BudgetAmountOption.tenK, label: '10k sats', sats: 10000),
  BudgetAmountOptionData(type: BudgetAmountOption.hundredK, label: '100k sats', sats: 100000),
  BudgetAmountOptionData(type: BudgetAmountOption.oneM, label: '1M sats', sats: 1000000),
  BudgetAmountOptionData(type: BudgetAmountOption.unlimited, label: 'Unlimited', sats: null),
  BudgetAmountOptionData(type: BudgetAmountOption.custom, label: 'Custom', sats: null),
];

enum ExpiryTimeOption { oneWeek, oneMonth, oneYear, never, custom }

class ExpiryTimeOptionData {
  const ExpiryTimeOptionData({required this.type, required this.label, this.minutes});

  final ExpiryTimeOption type;
  final String label;
  final int? minutes; // null for never
}

const List<ExpiryTimeOptionData> presetExpiryTimeOptions = <ExpiryTimeOptionData>[
  ExpiryTimeOptionData(type: ExpiryTimeOption.oneWeek, label: '1 week', minutes: 10080),
  ExpiryTimeOptionData(type: ExpiryTimeOption.oneMonth, label: '1 month', minutes: 43200),
  ExpiryTimeOptionData(type: ExpiryTimeOption.oneYear, label: '1 year', minutes: 525600),
  ExpiryTimeOptionData(type: ExpiryTimeOption.never, label: 'Never', minutes: null),
  ExpiryTimeOptionData(type: ExpiryTimeOption.custom, label: 'Custom', minutes: null),
];
