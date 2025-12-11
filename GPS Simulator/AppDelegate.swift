import UIKit
import CoreLocation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let locationManager = CLLocationManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 配置应用外观
        setupAppearance()
        
        // 请求位置权限
        requestLocationAuthorization()
        
        // 监听设备连接通知
        setupNotifications()
        
        // 创建窗口
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = createTabBarController()
        window?.makeKeyAndVisible()
        
        print("应用启动完成")
        return true
    }
    
    private func setupAppearance() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            
            // TabBar样式
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = .systemBackground
            UITabBar.appearance().standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
    }
    
    private func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeviceConnected(_:)),
            name: NSNotification.Name("DeviceConnected"),
            object: nil
        )
    }
    
    private func createTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()
        
        // 首页 - 设备信息
        let deviceVC = DeviceInfoViewController()
        deviceVC.tabBarItem = UITabBarItem(
            title: "设备信息",
            image: UIImage(systemName: "iphone"),
            selectedImage: UIImage(systemName: "iphone.fill")
        )
        let deviceNav = UINavigationController(rootViewController: deviceVC)
        
        // 地图 - 定位调试
        let mapVC = LocationMapViewController()
        mapVC.tabBarItem = UITabBarItem(
            title: "定位调试",
            image: UIImage(systemName: "map"),
            selectedImage: UIImage(systemName: "map.fill")
        )
        let mapNav = UINavigationController(rootViewController: mapVC)
        
        // 设置
        let settingsVC = SettingsViewController()
        settingsVC.tabBarItem = UITabBarItem(
            title: "设置",
            image: UIImage(systemName: "gear"),
            selectedImage: UIImage(systemName: "gear")
        )
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        
        tabBarController.viewControllers = [deviceNav, mapNav, settingsNav]
        return tabBarController
    }
    
    @objc private func handleDeviceConnected(_ notification: Notification) {
        print("设备连接通知: \(notification.userInfo ?? [:])")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("应用将进入后台")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("应用已进入后台")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("应用将进入前台")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("应用已激活")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("应用将终止")
    }
}