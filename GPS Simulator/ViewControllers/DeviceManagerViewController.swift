import UIKit
import ExternalAccessory

class DeviceManagerViewController: UIViewController {
    
    private var tableView: UITableView!
    private var accessories: [EAAccessory] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAccessories()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "设备管理"
        
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DeviceCell")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadAccessories() {
        accessories = EAAccessoryManager.shared().connectedAccessories
        tableView.reloadData()
    }
}

extension DeviceManagerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accessories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
        let accessory = accessories[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = accessory.name
        config.secondaryText = accessory.manufacturer
        config.image = UIImage(systemName: "externaldrive")
        
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let accessory = accessories[indexPath.row]
        showAlert(title: "设备信息", message: "名称: \(accessory.name)\n制造商: \(accessory.manufacturer)\n协议: \(accessory.protocolStrings.joined(separator: ", "))")
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}