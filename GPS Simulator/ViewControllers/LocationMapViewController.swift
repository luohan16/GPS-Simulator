import UIKit
import MapKit
import CoreLocation

class LocationMapViewController: UIViewController {
    
    // MARK: - Properties
    private var mapView: MKMapView!
    private var controlPanel: UIView!
    private var locationManager: CLLocationManager!
    private var currentLocation: CLLocation?
    private var simulatedLocation: CLLocationCoordinate2D?
    
    // 控制面板元素
    private var latTextField: UITextField!
    private var lonTextField: UITextField!
    private var altTextField: UITextField!
    private var statusLabel: UILabel!
    private var connectButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
        setupMapView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "定位调试"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 创建地图视图
        mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = .standard
        view.addSubview(mapView)
        
        // 创建控制面板
        controlPanel = createControlPanel()
        view.addSubview(controlPanel)
        
        // 添加地图长按手势
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress(_:)))
        mapView.addGestureRecognizer(longPressGesture)
        
        // 布局约束
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: controlPanel.topAnchor),
            
            controlPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlPanel.heightAnchor.constraint(equalToConstant: 220)
        ])
    }
    
    private func createControlPanel() -> UIView {
        let panel = UIView()
        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.backgroundColor = .systemBackground
        panel.layer.shadowColor = UIColor.black.cgColor
        panel.layer.shadowOffset = CGSize(width: 0, height: -2)
        panel.layer.shadowOpacity = 0.1
        panel.layer.shadowRadius = 4
        
        // 状态标签
        statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "状态: 未连接设备"
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = .systemRed
        statusLabel.textAlignment = .center
        panel.addSubview(statusLabel)
        
        // 输入框容器
        let inputStack = createInputStackView()
        panel.addSubview(inputStack)
        
        // 按钮容器
        let buttonStack = createButtonStackView()
        panel.addSubview(buttonStack)
        
        // 布局
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: panel.topAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
            
            inputStack.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            inputStack.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            inputStack.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
            
            buttonStack.topAnchor.constraint(equalTo: inputStack.bottomAnchor, constant: 16),
            buttonStack.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -20)
        ])
        
        return panel
    }
    
    private func createInputStackView() -> UIStackView {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        
        // 纬度输入
        let latRow = createInputRow(label: "纬度:", placeholder: "39.9042")
        latTextField = latRow.textField
        stack.addArrangedSubview(latRow)
        
        // 经度输入
        let lonRow = createInputRow(label: "经度:", placeholder: "116.4074")
        lonTextField = lonRow.textField
        stack.addArrangedSubview(lonRow)
        
        // 海拔输入
        let altRow = createInputRow(label: "海拔:", placeholder: "50.0")
        altTextField = altRow.textField
        altTextField.keyboardType = .decimalPad
        stack.addArrangedSubview(altRow)
        
        return stack
    }
    
    private func createInputRow(label: String, placeholder: String) -> UIView {
        let row = UIView()
        
        let labelView = UILabel()
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        labelView.textColor = .label
        labelView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.keyboardType = .decimalPad
        
        row.addSubview(labelView)
        row.addSubview(textField)
        
        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            labelView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            
            textField.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            textField.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // 使用关联对象存储textField
        objc_setAssociatedObject(row, "textField", textField, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        return row
    }
    
    private func createButtonStackView() -> UIStackView {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        
        // 连接按钮
        connectButton = createButton(title: "连接设备", backgroundColor: .systemBlue, action: #selector(connectDevice))
        stack.addArrangedSubview(connectButton)
        
        // 当前位置按钮
        let currentButton = createButton(title: "当前位置", backgroundColor: .systemGray, action: #selector(useCurrentLocation))
        stack.addArrangedSubview(currentButton)
        
        // 设置位置按钮
        let setButton = createButton(title: "设置位置", backgroundColor: .systemGreen, action: #selector(setLocation))
        stack.addArrangedSubview(setButton)
        
        return stack
    }
    
    private func createButton(title: String, backgroundColor: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    private func setupMapView() {
        // 设置默认区域（北京）
        let defaultCoordinate = CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
        let region = MKCoordinateRegion(
            center: defaultCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        mapView.setRegion(region, animated: false)
    }
    
    // MARK: - Actions
    @objc private func connectDevice() {
        let accessories = EAAccessoryManager.shared().connectedAccessories
        if accessories.isEmpty {
            showAlert(title: "未发现设备", message: "请连接GPS模拟器设备")
            statusLabel.text = "状态: 未连接"
            statusLabel.textColor = .systemRed
            connectButton.setTitle("连接设备", for: .normal)
            connectButton.backgroundColor = .systemBlue
        } else {
            showAlert(title: "设备已连接", message: "找到 \(accessories.count) 个外部设备")
            statusLabel.text = "状态: 已连接"
            statusLabel.textColor = .systemGreen
            connectButton.setTitle("断开连接", for: .normal)
            connectButton.backgroundColor = .systemRed
        }
    }
    
    @objc private func useCurrentLocation() {
        guard let location = currentLocation else {
            showAlert(title: "无法获取位置", message: "请确保已授予位置权限并等待定位完成")
            return
        }
        
        latTextField.text = String(format: "%.6f", location.coordinate.latitude)
        lonTextField.text = String(format: "%.6f", location.coordinate.longitude)
        
        // 更新地图显示
        updateMapLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        showToast(message: "已获取当前位置")
    }
    
    @objc private func setLocation() {
        guard let latText = latTextField.text, !latText.isEmpty,
              let lonText = lonTextField.text, !lonText.isEmpty else {
            showAlert(title: "输入错误", message: "请输入经纬度")
            return
        }
        
        guard let lat = Double(latText), lat >= -90 && lat <= 90,
              let lon = Double(lonText), lon >= -180 && lon <= 180 else {
            showAlert(title: "输入错误", message: "请输入有效的经纬度")
            return
        }
        
        let alt = Double(altTextField.text ?? "50.0") ?? 50.0
        
        // 模拟发送到设备
        simulatedLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        updateMapLocation(latitude: lat, longitude: lon)
        
        // 模拟发送命令
        let command = "SETLOC \(lat),\(lon)\nSETALT \(alt)"
        print("发送命令: \(command)")
        
        showToast(message: "位置已设置: \(lat), \(lon)")
    }
    
    @objc private func handleMapLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        latTextField.text = String(format: "%.6f", coordinate.latitude)
        lonTextField.text = String(format: "%.6f", coordinate.longitude)
        
        updateMapLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        showToast(message: "地图选点: \(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude))")
    }
    
    // MARK: - Helper Methods
    private func updateMapLocation(latitude: Double, longitude: Double) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        mapView.setRegion(region, animated: true)
        
        // 清除之前的标记
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        // 添加新标记
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "模拟位置"
        annotation.subtitle = String(format: "%.6f, %.6f", latitude, longitude)
        mapView.addAnnotation(annotation)
        
        // 选中标记
        mapView.selectAnnotation(annotation, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
    
    // MARK: - TextField Helper
    private func textField(for view: UIView) -> UITextField? {
        return objc_getAssociatedObject(view, "textField") as? UITextField
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位失败: \(error.localizedDescription)")
    }
}

// MARK: - MKMapViewDelegate
extension LocationMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        
        let identifier = "LocationMarker"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
}