import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = createTabBarController()
        window?.makeKeyAndVisible()
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

    func sceneDidDisconnect(_ scene: UIScene) {
        // 清理资源
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // 应用变为活跃状态
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // 应用将进入非活跃状态
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // 应用将进入前台
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // 应用已进入后台
    }
}