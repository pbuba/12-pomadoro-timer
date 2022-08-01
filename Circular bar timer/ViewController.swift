//
//  ViewController.swift
//  Circular bar timer
//
//  Created by Павел Бубликов on 21.06.2022.
//

import UIKit

class ViewController: UIViewController {
    
    let shapeView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }()
    
    private lazy var miniCircleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderColor = UIColor.systemGreen.cgColor
        view.layer.borderWidth = 2
        view.backgroundColor = .white
        return view
    }()
    
    let timerLabel: UILabel = {
        let label = UILabel()
        label.text = "25:00"
        label.font = UIFont.systemFont(ofSize: 50, weight: .thin)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    var imagePlay = UIImage(systemName: "play")
    let imagePause = UIImage(systemName: "pause")
    
    let timerControl: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "play")
        
        button.configuration = UIButton.Configuration.plain()
        button.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(scale: .large)
        button.setTitle("", for: .normal)
        button.setImage(image, for: .normal)
        button.tintColor = .systemGreen
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    var timer = Timer()
    var time: Int = 5
    var isWorkTime: Bool = true
    
    let shapeLayer = CAShapeLayer()

    var isActive: Bool = false {
        willSet {
            if newValue {
                timerControl.setImage(imagePause, for: .normal)
            } else {
                timerControl.setImage(imagePlay, for: .normal)
            }
        }
    }
    
    public func stringFormat() -> String {
        let minutes = time / 60 % 60
        let seconds = time % 60
        return String(format: "%02i:%02i", minutes, seconds)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        animationCircular(color: .systemGreen)
        shapeView.layer.cornerRadius = shapeView.frame.width / 2.0
        miniCircleView.layer.cornerRadius = miniCircleView.frame.width / 2.0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        timerLabel.text = stringFormat()
        
        setupLayout()
        
        timerControl.addTarget(self, action: #selector(clickTimerControl), for: .touchUpInside)
    }

    
    @objc func clickTimerControl() {
        isActive = !isActive
        
        if (isActive) {
            if shapeView.layer.speed == .zero {
                resumeLayer(layer: shapeView.layer)
                resumeLayer(layer: miniCircleView.layer)
            } else {
                basicAnimation()
                animationMiniCircle()
            }
            
            timer = Timer.scheduledTimer(
                timeInterval: 1,
                target: self,
                selector: #selector(timerAction),
                userInfo: nil,
                repeats: true
            )
        } else {
            timer.invalidate()
            pauseLayer(layer: shapeView.layer)
            pauseLayer(layer: miniCircleView.layer)
        }
    }
    
    @objc func timerAction() {
        if time < 2 {
            isActive = false
            
            isWorkTime = !isWorkTime
            let min = isWorkTime ? 2 : 1
            let color: UIColor = isWorkTime ? .systemGreen : .systemRed
            animationCircular(color: color)
            timerControl.tintColor = isWorkTime ? .systemGreen : .systemRed
            miniCircleView.layer.borderColor = isWorkTime ? UIColor.systemGreen.cgColor : UIColor.systemRed.cgColor
            
            time = min * 60
            timerLabel.text = stringFormat()
            timer.invalidate()
        } else {
            time -= 1
            timerLabel.text = stringFormat()
        }
    }
    
    //MARK: Animation
    
    func animationCircular(color: UIColor) {
        let center = CGPoint(x: shapeView.frame.width / 2, y: shapeView.frame.height / 2)
        
        let endAngle = (-CGFloat.pi / 2)
        let startAngle = 2 * CGFloat.pi + endAngle
        
        let circularPath = UIBezierPath(arcCenter: center, radius: 100, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        shapeLayer.path = circularPath.cgPath
        shapeLayer.lineWidth = 4
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeEnd = 1
        shapeLayer.lineCap = CAShapeLayerLineCap.butt
        shapeLayer.strokeColor = color.cgColor
        
        shapeView.layer.addSublayer(shapeLayer)
    }
    
    func animationMiniCircle() {
        // Создаем UIBezierPath
        let path = UIBezierPath()
        
        // Начальная точка, с которой должна начинаться анимация
        let initPoint = getPoint(for: -90)
        path.move(to: initPoint)
        
        // Чтобы анимация miniCircleView проходила через всю границу большого круга
        for angle in -89...0 { path.addLine(to: getPoint(for: angle)) }
        for angle in 1...270 { path.addLine(to: getPoint(for: angle)) }
        
        path.close()
        animate(view: miniCircleView, path: path)
    }
    
    func animate(view: UIView, path: UIBezierPath) {
        // Создаем CAKeyframeAnimationэкземпляр
        let animation = CAKeyframeAnimation(keyPath: "position")

        // Сообщаем анимации о предварительно рассчитанном ранее пути Безье
        animation.path = path.cgPath

        // Чтобы анимация запускалась только один раз
        animation.repeatCount = 1

        // Чтобы продолжительность каждого цикла анимации составляла time секунд
        animation.duration = CFTimeInterval(time)

        // Добавляем анимацию к слою представления с помощью ключа, чтобы позже мы могли получить анимацию и удалить ее, если это необходимо
        view.layer.add(animation, forKey: "animation")
    }
    
    func basicAnimation() {
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        
        basicAnimation.toValue = 0
        basicAnimation.duration = CFTimeInterval(time)
        basicAnimation.fillMode = CAMediaTimingFillMode.forwards
        basicAnimation.isRemovedOnCompletion = true
        
        shapeLayer.add(basicAnimation, forKey: "basicAnimation")
    }
    
    func pauseLayer(layer: CALayer) {
        let pausedTime: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }
    
    func resumeLayer(layer: CALayer) {
        let pausedTime: CFTimeInterval = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    
    func getPoint(for angle: Int) -> CGPoint {
        
        // Получаем радиус большого круга
        let radius = Double(self.shapeView.layer.cornerRadius)

        // Переводим угол из градусов в радианы
        let radian = Double(angle) * Double.pi / Double(180)

        // Мы вычисляем точку на границе круга. Тут что-то странное и математическое
        let newCenterX = shapeView.center.x + radius * cos(radian)
        let newCenterY = shapeView.center.y + radius * sin(radian)

        return CGPoint(x: newCenterX, y: newCenterY)
    }
}

extension ViewController {
    func setupLayout() {
        view.addSubview(shapeView)
        
        NSLayoutConstraint.activate([
            shapeView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shapeView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            shapeView.widthAnchor.constraint(equalToConstant: 200),
            shapeView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        shapeView.addSubview(timerLabel)
        NSLayoutConstraint.activate([
            timerLabel.centerXAnchor.constraint(equalTo: shapeView.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: shapeView.centerYAnchor, constant: -20),
        ])
        
        view.addSubview(timerControl)
        NSLayoutConstraint.activate([
            timerControl.centerXAnchor.constraint(equalTo: shapeView.centerXAnchor),
            timerControl.centerYAnchor.constraint(equalTo: shapeView.centerYAnchor, constant: 40),
        ])
        
        view.addSubview(miniCircleView)
        NSLayoutConstraint.activate([
            miniCircleView.centerXAnchor.constraint(equalTo: shapeView.centerXAnchor),
            miniCircleView.centerYAnchor.constraint(equalTo: shapeView.topAnchor),
            miniCircleView.widthAnchor.constraint(equalToConstant: 24),
            miniCircleView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}

