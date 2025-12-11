import UIKit
import ExternalAccessory
import CoreLocation
import SystemConfiguration.CaptiveNetwork

class DeviceInfoViewController: UIViewController {
    
    // MARK: - Properties
    private var tableView: UITableView!
    private var refreshControl = UIRefreshControl()
    private var deviceInfoSections: [DeviceInfoSection] = []
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDeviceInfo()
        setupLocationManager()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "设备信息"
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
        tableView.register(DeviceInfoCell.self, forCellReuseIdentifier: "DeviceInfoCell")
        tableView.register(DeviceInfoHeaderView.self, forHeaderFooterViewReuseIdentifier: "DeviceInfoHeaderView")
        
        // 添加刷新控件
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        view.addSubview(tableView)
        
        // 添加扫描按钮
        let scanButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(scanDevices)
        )
        navigationItem.rightBarButtonItem = scanButton
        
        // 布局约束
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    // MARK: - Data Loading
    @objc private func refreshData() {
        loadDeviceInfo()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshControl.endRefreshing()
        }
    }
    
    @objc private func scanDevices() {
        let accessories = EAAccessoryManager.shared().connectedAccessories
        if accessories.isEmpty {
            showAlert(title: "未发现设备", message: "请连接GPS模拟器设备")
        } else {
            showAlert(title: "发现设备", message: "找到 \(accessories.count) 个外部设备")
        }
    }
    
    private func loadDeviceInfo() {
        deviceInfoSections = [
            createSystemInfoSection(),
            createHardwareInfoSection(),
            createNetworkInfoSection(),
            createLocationInfoSection(),
            createAppInfoSection(),
            createExternalAccessorySection()
        ]
        
        tableView.reloadData()
    }
    
    // MARK: - Section Creation
    private func createSystemInfoSection() -> DeviceInfoSection {
        let systemInfo = [
            DeviceInfoItem(title: "设备型号", value: UIDevice.current.model),
            DeviceInfoItem(title: "系统版本", value: UIDevice.current.systemVersion),
            DeviceInfoItem(title: "设备名称", value: UIDevice.current.name),
            DeviceInfoItem(title: "系统名称", value: UIDevice.current.systemName),
            DeviceInfoItem(title: "UUID", value: UIDevice.current.identifierForVendor?.uuidString ?? "未知"),
            DeviceInfoItem(title: "电池状态", value: getBatteryInfo()),
            DeviceInfoItem(title: "时区", value: TimeZone.current.identifier)
        ]
        
        return DeviceInfoSection(title: "系统信息", icon: "gear", items: systemInfo)
    }
    
    private func createHardwareInfoSection() -> DeviceInfoSection {
        let hardwareInfo = [
            DeviceInfoItem(title: "处理器核心数", value: "\(ProcessInfo.processInfo.processorCount) 核"),
            DeviceInfoItem(title: "物理内存", value: "\(getPhysicalMemory()) GB"),
            DeviceInfoItem(title: "存储空间", value: getStorageInfo()),
            DeviceInfoItem(title: "屏幕尺寸", value: "\(UIScreen.main.bounds.width) × \(UIScreen.main.bounds.height)"),
            DeviceInfoItem(title: "屏幕比例", value: "\(UIScreen.main.scale)x"),
            DeviceInfoItem(title: "是否越狱", value: isJailbroken() ? "是" : "否")
        ]
        
        return DeviceInfoSection(title: "硬件信息", icon: "cpu", items: hardwareInfo)
    }
    
    private func createNetworkInfoSection() -> DeviceInfoSection {
        let networkInfo = [
            DeviceInfoItem(title: "WiFi SSID", value: getWiFiSSID() ?? "未连接"),
            DeviceInfoItem(title: "IP地址", value: getIPAddress() ?? "未知"),
            DeviceInfoItem(title: "网络类型", value: getNetworkType()),
            DeviceInfoItem(title: "运营商", value: getCarrierName() ?? "未知")
        ]
        
        return DeviceInfoSection(title: "网络信息", icon: "wifi", items: networkInfo)
    }
    
    private func createLocationInfoSection() -> DeviceInfoSection {
        var locationItems = [
            DeviceInfoItem(title: "定位服务", value: CLLocationManager.locationServicesEnabled() ? "已启用" : "已禁用"),
            DeviceInfoItem(title: "定位权限", value: getLocationAuthorizationStatus())
        ]
        
        if let location = currentLocation {
            locationItems.append(contentsOf: [
                DeviceInfoItem(title: "当前纬度", value: String(format: "%.6f", location.coordinate.latitude)),
                DeviceInfoItem(title: "当前经度", value: String(format: "%.6f", location.coordinate.longitude)),
                DeviceInfoItem(title: "海拔高度", value: String(format: "%.1f 米", location.altitude)),
                DeviceInfoItem(title: "水平精度", value: String(format: "%.1f 米", location.horizontalAccuracy)),
                DeviceInfoItem(title: "垂直精度", value: String(format: "%.1f 米", location.verticalAccuracy))
            ])
        }
        
        return DeviceInfoSection(title: "定位信息", icon: "location", items: locationItems)
    }
    
    private func createAppInfoSection() -> DeviceInfoSection {
        let appInfo = [
            DeviceInfoItem(title: "应用版本", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知"),
            DeviceInfoItem(title: "构建版本", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "未知"),
            DeviceInfoItem(title: "应用名称", value: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "未知"),
            DeviceInfoItem(title: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "未知"),
            DeviceInfoItem(title: "启动次数", value: "\(UserDefaults.standard.integer(forKey: "launchCount")) 次")
        ]
        
        return DeviceInfoSection(title: "应用信息", icon: "app", items: appInfo)
    }
    
    private func createExternalAccessorySection() -> DeviceInfoSection {
        let accessories = EAAccessoryManager.shared().connectedAccessories
        var accessoryItems: [DeviceInfoItem] = []
        
        if accessories.isEmpty {
            accessoryItems.append(DeviceInfoItem(title: "状态", value: "未连接外部设备"))
        } else {
            accessoryItems.append(DeviceInfoItem(title: "已连接设备", value: "\(accessories.count) 个"))
            
            for (index, accessory) in accessories.enumerated() {
                accessoryItems.append(DeviceInfoItem(
                    title: "设备 \(index + 1)",
                    value: "\(accessory.name) (\(accessory.manufacturer))"
                ))
                accessoryItems.append(DeviceInfoItem(
                    title: "协议",
                    value: accessory.protocolStrings.joined(separator: ", ")
                ))
                accessoryItems.append(DeviceInfoItem(
                    title: "序列号",
                    value: accessory.serialNumber
                ))
            }
        }
        
        return DeviceInfoSection(title: "外部设备", icon: "externaldrive", items: accessoryItems)
    }
    
    // MARK: - Helper Methods
    private func getBatteryInfo() -> String {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = Int(UIDevice.current.batteryLevel * 100)
        let batteryState = UIDevice.current.batteryState
        
        var stateString = ""
        switch batteryState {
        case .charging:
            stateString = "充电中"
        case .full:
            stateString = "已充满"
        case .unplugged:
            stateString = "未充电"
        case .unknown:
            stateString = "未知"
        @unknown default:
            stateString = "未知"
        }
        
        return "\(batteryLevel)% (\(stateString))"
    }
    
    private func getPhysicalMemory() -> String {
        let memory = ProcessInfo.processInfo.physicalMemory
        let memoryInGB = Double(memory) / 1_000_000_000
        return String(format: "%.1f", memoryInGB)
    }
    
    private func getStorageInfo() -> String {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            let totalSpace = (attributes[.systemSize] as? NSNumber)?.int64Value ?? 0
            let freeSpace = (attributes[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
            let usedSpace = totalSpace - freeSpace
            
            let usedGB = Double(usedSpace) / 1_000_000_000
            let totalGB = Double(totalSpace) / 1_000_000_000
            
            return String(format: "已用 %.1fGB / 总共 %.1fGB", usedGB, totalGB)
        } catch {
            return "获取失败"
        }
    }
    
    private func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
            return false
        #else
            let paths = [
                "/Applications/Cydia.app",
                "/Library/MobileSubstrate/MobileSubstrate.dylib",
                "/bin/bash",
                "/usr/sbin/sshd",
                "/etc/apt"
            ]
            
            for path in paths {
                if FileManager.default.fileExists(atPath: path) {
                    return true
                }
            }
            
            return false
        #endif
    }
    
    private func getWiFiSSID() -> String? {
        #if targetEnvironment(simulator)
            return "Simulator WiFi"
        #else
            guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return nil }
            for interface in interfaces {
                guard let interfaceInfo = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] else { continue }
                guard let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String else { continue }
                return ssid
            }
            return nil
        #endif
    }
    
    private func getIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // IPv4
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr,
                               socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname,
                               socklen_t(hostname.count),
                               nil,
                               socklen_t(0),
                               NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return address
    }
    
    private func getNetworkType() -> String {
        let reachability = SCNetworkReachabilityCreateWithName(nil, "www.apple.com")
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability!, &flags)
        
        if flags.contains(.isWWAN) {
            return "蜂窝网络"
        } else if flags.contains(.reachable) {
            return "WiFi"
        } else {
            return "无网络"
        }
    }
    
    private func getCarrierName() -> String? {
        #if targetEnvironment(simulator)
            return "Simulator"
        #else
            // 需要导入 CoreTelephony
            // import CoreTelephony
            // let networkInfo = CTTelephonyNetworkInfo()
            // let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value
            // return carrier?.carrierName
            return "需要CoreTelephony框架"
        #endif
    }
    
    private func getLocationAuthorizationStatus() -> String {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .notDetermined:
            return "未决定"
        case .restricted:
            return "受限制"
        case .denied:
            return "已拒绝"
        case .authorizedAlways:
            return "始终允许"
        case .authorizedWhenInUse:
            return "使用时允许"
        @unknown default:
            return "未知"
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension DeviceInfoViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return deviceInfoSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceInfoSections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceInfoCell", for: indexPath) as! DeviceInfoCell
        let item = deviceInfoSections[indexPath.section].items[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "DeviceInfoHeaderView") as! DeviceInfoHeaderView
        let sectionInfo = deviceInfoSections[section]
        header.configure(title: sectionInfo.title, iconName: sectionInfo.icon)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = deviceInfoSections[indexPath.section].items[indexPath.row]
        
        // 复制到剪贴板
        UIPasteboard.general.string = item.value
        showToast(message: "已复制: \(item.value)")
    }
    
    private func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension DeviceInfoViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
            // 更新位置信息部分
            if let locationSectionIndex = deviceInfoSections.firstIndex(where: { $0.title == "定位信息" }) {
                deviceInfoSections[locationSectionIndex] = createLocationInfoSection()
                tableView.reloadSections(IndexSet(integer: locationSectionIndex), with: .none)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位失败: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // 更新定位权限显示
        if let locationSectionIndex = deviceInfoSections.firstIndex(where: { $0.title == "定位信息" }) {
            deviceInfoSections[locationSectionIndex] = createLocationInfoSection()
            tableView.reloadSections(IndexSet(integer: locationSectionIndex), with: .none)
        }
    }
}

// MARK: - Data Models
struct DeviceInfoSection {
    let title: String
    let icon: String
    let items: [DeviceInfoItem]
}

struct DeviceInfoItem {
    let title: String
    let value: String
}

// MARK: - Custom Cells
class DeviceInfoCell: UITableViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .right
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4),
            
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8)
        ])
    }
    
    func configure(with item: DeviceInfoItem) {
        titleLabel.text = item.title
        valueLabel.text = item.value
        accessoryType = .none
        selectionStyle = .default
    }
}

class DeviceInfoHeaderView: UITableViewHeaderFooterView {
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
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
        contentView.backgroundColor = .systemBackground
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(title: String, iconName: String) {
        titleLabel.text = title
        iconImageView.image = UIImage(systemName: iconName)
    }
}