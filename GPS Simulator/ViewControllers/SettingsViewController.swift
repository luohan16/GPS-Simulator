import UIKit
import MessageUI

class SettingsViewController: UIViewController {
    
    // MARK: - Properties
    private var tableView: UITableView!
    private var settingsSections: [SettingsSection] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSettings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "设置"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 配置表格视图
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SettingsCell.self, forCellReuseIdentifier: "SettingsCell")
        tableView.register(SettingsHeaderView.self, forHeaderFooterViewReuseIdentifier: "SettingsHeaderView")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadSettings() {
        settingsSections = [
            createDeviceSettingsSection(),
            createAppSettingsSection(),
            createAboutSection()
        ]
        
        tableView.reloadData()
    }
    
    // MARK: - Section Creation
    private func createDeviceSettingsSection() -> SettingsSection {
        let items = [
            SettingsItem(
                title: "设备连接",
                subtitle: "管理外部设备连接",
                icon: "externaldrive.connected.to.line.below",
                type: .navigation,
                action: { [weak self] in
                    self?.navigateToDeviceManager()
                }
            ),
            SettingsItem(
                title: "蓝牙设置",
                subtitle: "配置蓝牙连接",
                icon: "bluetooth",
                type: .navigation,
                action: { [weak self] in
                    self?.openBluetoothSettings()
                }
            ),
            SettingsItem(
                title: "位置服务",
                subtitle: "定位权限设置",
                icon: "location",
                type: .navigation,
                action: { [weak self] in
                    self?.openLocationSettings()
                }
            )
        ]
        
        return SettingsSection(title: "设备设置", items: items)
    }
    
    private func createAppSettingsSection() -> SettingsSection {
        let items = [
            SettingsItem(
                title: "通知设置",
                subtitle: "管理应用通知",
                icon: "bell",
                type: .switch,
                action: { [weak self] in
                    self?.toggleNotifications()
                }
            ),
            SettingsItem(
                title: "数据缓存",
                subtitle: "清除缓存数据",
                icon: "trash",
                type: .destructive,
                action: { [weak self] in
                    self?.clearCache()
                }
            ),
            SettingsItem(
                title: "日志记录",
                subtitle: "启用调试日志",
                icon: "doc.text",
                type: .switch,
                action: { [weak self] in
                    self?.toggleLogging()
                }
            ),
            SettingsItem(
                title: "自动连接",
                subtitle: "启动时自动连接设备",
                icon: "link",
                type: .switch,
                action: { [weak self] in
                    self?.toggleAutoConnect()
                }
            )
        ]
        
        return SettingsSection(title: "应用设置", items: items)
    }
    
    private func createAboutSection() -> SettingsSection {
        let items = [
            SettingsItem(
                title: "关于应用",
                subtitle: "版本信息和说明",
                icon: "info.circle",
                type: .navigation,
                action: { [weak self] in
                    self?.showAbout()
                }
            ),
            SettingsItem(
                title: "用户反馈",
                subtitle: "发送建议或问题",
                icon: "envelope",
                type: .navigation,
                action: { [weak self] in
                    self?.sendFeedback()
                }
            ),
            SettingsItem(
                title: "评分支持",
                subtitle: "在App Store评分",
                icon: "star",
                type: .navigation,
                action: { [weak self] in
                    self?.rateApp()
                }
            ),
            SettingsItem(
                title: "分享应用",
                subtitle: "分享给朋友",
                icon: "square.and.arrow.up",
                type: .navigation,
                action: { [weak self] in
                    self?.shareApp()
                }
            )
        ]
        
        return SettingsSection(title: "关于", items: items)
    }
    
    // MARK: - Actions
    private func navigateToDeviceManager() {
        let deviceVC = DeviceManagerViewController()
        navigationController?.pushViewController(deviceVC, animated: true)
    }
    
    private func openBluetoothSettings() {
        if let url = URL(string: "App-Prefs:root=Bluetooth") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func openLocationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func toggleNotifications() {
        let isEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        UserDefaults.standard.set(!isEnabled, forKey: "notificationsEnabled")
        showToast(message: isEnabled ? "通知已关闭" : "通知已开启")
    }
    
    private func clearCache() {
        let alert = UIAlertController(
            title: "清除缓存",
            message: "确定要清除所有缓存数据吗？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清除", style: .destructive, handler: { _ in
            // 清除缓存逻辑
            URLCache.shared.removeAllCachedResponses()
            
            // 清除UserDefaults部分数据
            let defaults = UserDefaults.standard
            let preservedKeys = ["notificationsEnabled", "loggingEnabled", "autoConnectEnabled"]
            let allKeys = defaults.dictionaryRepresentation().keys
            
            for key in allKeys {
                if !preservedKeys.contains(key) {
                    defaults.removeObject(forKey: key)
                }
            }
            
            defaults.synchronize()
            
            self.showToast(message: "缓存已清除")
        }))
        
        present(alert, animated: true)
    }
    
    private func toggleLogging() {
        let isEnabled = UserDefaults.standard.bool(forKey: "loggingEnabled")
        UserDefaults.standard.set(!isEnabled, forKey: "loggingEnabled")
        showToast(message: isEnabled ? "日志记录已关闭" : "日志记录已开启")
    }
    
    private func toggleAutoConnect() {
        let isEnabled = UserDefaults.standard.bool(forKey: "autoConnectEnabled")
        UserDefaults.standard.set(!isEnabled, forKey: "autoConnectEnabled")
        showToast(message: isEnabled ? "自动连接已关闭" : "自动连接已开启")
    }
    
    private func showAbout() {
        let aboutVC = AboutViewController()
        navigationController?.pushViewController(aboutVC, animated: true)
    }
    
    private func sendFeedback() {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(["support@example.com"])
            mailComposer.setSubject("GPS模拟器控制端反馈")
            
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            let deviceModel = UIDevice.current.model
            let systemVersion = UIDevice.current.systemVersion
            
            let messageBody = """
            
            ---
            设备信息:
            应用版本: \(appVersion)
            设备型号: \(deviceModel)
            系统版本: \(systemVersion)
            """
            
            mailComposer.setMessageBody(messageBody, isHTML: false)
            present(mailComposer, animated: true)
        } else {
            showAlert(title: "无法发送邮件", message: "请检查邮件设置")
        }
    }
    
    private func rateApp() {
        guard let appID = "YOUR_APP_ID" as? String else { return }
        let urlStr = "https://itunes.apple.com/app/id\(appID)?action=write-review"
        
        if let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func shareApp() {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "GPS模拟器控制端"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let shareText = "推荐使用 \(appName) v\(appVersion) - 专业的GPS模拟器控制工具"
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        present(activityVC, animated: true)
    }
    
    private func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingsSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsSections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
        let item = settingsSections[indexPath.section].items[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SettingsHeaderView") as! SettingsHeaderView
        header.configure(title: settingsSections[section].title)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = settingsSections[indexPath.section].items[indexPath.row]
        item.action?()
    }
}

// MARK: - MFMailComposeViewControllerDelegate
extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            switch result {
            case .sent:
                self.showToast(message: "反馈已发送")
            case .failed:
                self.showToast(message: "发送失败")
            case .cancelled:
                break
            case .saved:
                self.showToast(message: "已保存到草稿")
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Data Models
struct SettingsSection {
    let title: String
    let items: [SettingsItem]
}

struct SettingsItem {
    enum ItemType {
        case navigation
        case `switch`
        case destructive
    }
    
    let title: String
    let subtitle: String?
    let icon: String
    let type: ItemType
    let action: (() -> Void)?
}

// MARK: - Custom Cells
class SettingsCell: UITableViewCell {
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let switchControl: UISwitch = {
        let switchControl = UISwitch()
        return switchControl
    }()
    
    private let accessoryImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .tertiaryLabel
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with item: SettingsItem) {
        iconImageView.image = UIImage(systemName: item.icon)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        
        // 清除之前的视图
        switchControl.removeFromSuperview()
        accessoryImageView.removeFromSuperview()
        accessoryType = .none
        
        // 根据类型配置
        switch item.type {
        case .navigation:
            accessoryType = .disclosureIndicator
            
        case .switch:
            contentView.addSubview(switchControl)
            switchControl.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
            
            // 根据设置配置开关状态
            switch item.title {
            case "通知设置":
                switchControl.isOn = UserDefaults.standard.bool(forKey: "notificationsEnabled")
            case "日志记录":
                switchControl.isOn = UserDefaults.standard.bool(forKey: "loggingEnabled")
            case "自动连接":
                switchControl.isOn = UserDefaults.standard.bool(forKey: "autoConnectEnabled")
            default:
                break
            }
            
            switchControl.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
            
        case .destructive:
            titleLabel.textColor = .systemRed
            iconImageView.tintColor = .systemRed
        }
    }
    
    @objc private func switchValueChanged(_ sender: UISwitch) {
        // 开关状态变化处理
        print("开关状态改变: \(sender.isOn)")
    }
}

class SettingsHeaderView: UITableViewHeaderFooterView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        return label
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .systemGroupedBackground
        
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(title: String) {
        titleLabel.text = title.uppercased()
    }
}