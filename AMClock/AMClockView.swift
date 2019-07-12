//
//  AMClockView.swift
//  AMClockView, https://github.com/adventam10/AMClockView
//
//  Created by am10 on 2017/12/29.
//  Copyright © 2017年 am10. All rights reserved.
//

import UIKit

public enum AMCVTimeEditType{
    case none
    case hour
    case minute
}

public enum AMCVDateFormat:String {
    case hour = "HH"
    case minute = "mm"
    case time = "HH:mm"
}

public enum AMCVClockType {
    case none
    case arabic
    case roman
    func timeLabelTitleList() -> [String] {
        
        switch self {
        case .none:
            return []
        case .arabic:
            return ["12", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"]
        case .roman:
            return []
//            return ["Ⅻ", "Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ", "Ⅴ", "Ⅵ", "Ⅶ", "Ⅷ", "Ⅸ", "Ⅹ", "Ⅺ"]
        }
    }
}

public protocol AMClockViewDelegate: class {
    
    func clockView(clockView:AMClockView, didChangeDate date:Date)
}

@IBDesignable public class AMClockView: UIView {
    
    private let clockSpace:CGFloat = 10
    
    private let clockView = UIView()
    
    private let clockImageView = UIImageView()
    
    private let minuteHandImageView = UIImageView()
    
    private let hourHandImageView = UIImageView()
    
    private var drawLayer:CAShapeLayer?
    
    private var hourHandLayer:CAShapeLayer?
    
    private var minuteHandLayer:CAShapeLayer?
    
    private var panHourLayer:CAShapeLayer?
    
    private var panMinuteLayer:CAShapeLayer?
    
    private var tapHourLayer:CAShapeLayer?
    
    private var tapMinuteLayer:CAShapeLayer?
    
    private let selectedTimeLabel = UILabel()
    
    private let dateFormatter = DateFormatter()
    
    private let calendar = Calendar(identifier: .gregorian)
    
    private var editType = AMCVTimeEditType.none

    private var startAngle:Float = 0.0
    
    private var endAngle:Float = 0.0
    
    private var currentDate = Date()
    
    override public var bounds: CGRect {
        
        didSet {
            
            redrawClock()
        }
    }
    
    public weak var delegate: AMClockViewDelegate?
    
    /// watch dials
    public var clockType = AMCVClockType.arabic
    
    @IBInspectable public var clockBorderLineWidth:CGFloat = 5.0
    
    @IBInspectable public var smallClockIndexWidth:CGFloat = 1.0
    
    @IBInspectable public var clockIndexWidth:CGFloat = 2.0
    
    @IBInspectable public var hourHandWidth:CGFloat = 5.0
    
    @IBInspectable public var minuteHandWidth:CGFloat = 3.0
    
    @IBInspectable public var clockBorderLineColor:UIColor = UIColor.black
    
    @IBInspectable public var centerCircleLineColor:UIColor = UIColor.darkGray
    
    @IBInspectable public var hourHandColor:UIColor = UIColor.black
    
    @IBInspectable public var minuteHandColor:UIColor = UIColor.black
    
    @IBInspectable public var selectedTimeLabelTextColor:UIColor = UIColor.black
    
    @IBInspectable public var timeLabelTextColor:UIColor = UIColor.black
    
    @IBInspectable public var smallClockIndexColor:UIColor = UIColor.black
    
    @IBInspectable public var clockIndexColor:UIColor = UIColor.black
    
    @IBInspectable public var clockColor:UIColor = UIColor.clear
    
    @IBInspectable public var clockImage:UIImage?
    
    @IBInspectable public var minuteHandImage:UIImage?
    
    @IBInspectable public var hourHandImage:UIImage?
    
    @IBInspectable public var isShowSelectedTime:Bool = false {
        
        didSet {
            
            selectedTimeLabel.isHidden = !isShowSelectedTime
        }
    }

    public var selectedDate:Date? {
        
        didSet{
            
            if let selectedDate = selectedDate {
                
                currentDate = selectedDate
                
            } else {
                
                currentDate = Date()
            }
            
            redrawClock()
        }
    }
    
    //MARK:Initialize
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder:aDecoder)
        initView()
    }
    
    override public init(frame: CGRect) {
        
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        initView()
    }
    
    convenience init() {
        
        self.init(frame: CGRect.zero)
    }
    
    private func initView() {
        
        dateFormatter.locale = Locale(identifier: "ja_JP")
    }
    
    override public func draw(_ rect: CGRect) {
        
        redrawClock()
    }
    
    //MARK: Prepare
    private func prepareClockView() {
        
        var length:CGFloat = (frame.width < frame.height) ? frame.width : frame.height
        length -= clockSpace*2
        clockView.frame = CGRect(x: frame.width/2 - length/2,
                                 y: frame.height/2 - length/2,
                                 width: length,
                                 height: length)
        addSubview(clockView)
    }
    
    private func prepareClockImageViews() {
        
        clockImageView.frame = clockView.bounds
        minuteHandImageView.frame = clockView.bounds
        hourHandImageView.frame = clockView.bounds
        
        clockImageView.image = clockImage
        minuteHandImageView.image = minuteHandImage
        hourHandImageView.image = hourHandImage
        
        clockView.addSubview(clockImageView)
        clockView.addSubview(hourHandImageView)
        clockView.addSubview(minuteHandImageView)
    }
    
    private func prepareSelectedTimeLabel() {
        
        let radius:CGFloat = clockView.frame.width/2
        let centerPoint = CGPoint(x: radius, y: radius)
        selectedTimeLabel.frame = CGRect(x: centerPoint.x - (radius/2)/2,
                                         y: centerPoint.y - radius/3,
                                         width: radius/2,
                                         height: radius/3)
        clockView.addSubview(selectedTimeLabel)
        selectedTimeLabel.font = adjustFont(rect: selectedTimeLabel.frame)
        selectedTimeLabel.adjustsFontSizeToFitWidth = true
        selectedTimeLabel.textColor = selectedTimeLabelTextColor
        selectedTimeLabel.textAlignment = .center
        selectedTimeLabel.isHidden = !isShowSelectedTime
    }
    
    private func prepareDrawLayer() {
        
        drawLayer = CAShapeLayer()
        guard let drawLayer = drawLayer else {
            
            return;
        }
        
        drawLayer.frame = clockView.bounds
        clockView.layer.addSublayer(drawLayer)
        drawLayer.cornerRadius = 2000 * clockView.frame.width / 2930
        drawLayer.masksToBounds = true
        
        if clockImage == nil {
            
            drawLayer.borderWidth = clockBorderLineWidth
            drawLayer.borderColor = clockBorderLineColor.cgColor
        }
    }
    
    private func prepareSmallClockIndexLayer() {
        
        guard let drawLayer = drawLayer else {
            
            return;
        }
        
        let layer = CAShapeLayer()
        layer.frame = drawLayer.bounds
        drawLayer.addSublayer(layer)
        layer.strokeColor = smallClockIndexColor.cgColor
        layer.fillColor = UIColor.clear.cgColor;
        
        var angle:Float = Float(Double.pi/2 + Double.pi)
        let radius:CGFloat = clockView.frame.width/2
        let centerPoint = CGPoint(x: radius, y: radius)
        let smallRadius:CGFloat = radius - (radius/20 + clockBorderLineWidth)
        
        let path = UIBezierPath()
        // 中心から外への線描画
        for i in 0..<60 {
            
            if i%5 != 0 {
                
                let point = CGPoint(x: centerPoint.x + radius * CGFloat(cosf(angle)),
                                    y: centerPoint.y + radius * CGFloat(sinf(angle)))
                path.move(to: point)
                let point2 = CGPoint(x: centerPoint.x + smallRadius * CGFloat(cosf(angle)),
                                     y: centerPoint.y + smallRadius * CGFloat(sinf(angle)))
                path.addLine(to: point2)
            }
            
            angle += Float(Double.pi/30)
        }
        layer.lineWidth = smallClockIndexWidth
        layer.path = path.cgPath
    }
    
    private func prepareClockIndexLayer() {
        
        guard let drawLayer = drawLayer else {
            
            return;
        }
        
        let layer = CAShapeLayer()
        layer.frame = drawLayer.bounds
        drawLayer.addSublayer(layer)
        layer.strokeColor = clockIndexColor.cgColor
        layer.fillColor = UIColor.clear.cgColor;
        
        var angle:Float = Float(Double.pi/2 + Double.pi)
        let radius:CGFloat = clockView.frame.width/2
        let centerPoint = CGPoint(x: radius, y: radius)
        let smallRadius:CGFloat = radius - (radius/10 + clockBorderLineWidth)
        
        let path = UIBezierPath()
        // 中心から外への線描画
        for _ in 0..<12 {
            
            let point = CGPoint(x: centerPoint.x + radius * CGFloat(cosf(angle)),
                                y: centerPoint.y + radius * CGFloat(sinf(angle)))
            path.move(to: point)
            let point2 = CGPoint(x: centerPoint.x + smallRadius * CGFloat(cosf(angle)),
                                 y: centerPoint.y + smallRadius * CGFloat(sinf(angle)))
            path.addLine(to: point2)
            angle += Float(Double.pi/6)
        }
        layer.lineWidth = clockIndexWidth
        layer.path = path.cgPath
    }
    
    private func prepareTimeLabel() {
        
        var angle:Float = Float(Double.pi/2 + Double.pi)
        let radius:CGFloat = clockView.frame.width/2
        let centerPoint = CGPoint(x: radius, y: radius)
        var smallRadius:CGFloat = radius - (radius/10 + clockBorderLineWidth)
        let length:CGFloat = radius/4
        smallRadius -= length/2
        
        // 中心から外への線描画
        for i in 0..<12 {
            
            let label = UILabel(frame: CGRect(x: 0,
                                              y: 0,
                                              width: length,
                                              height: length))
            label.adjustsFontSizeToFitWidth = true
            label.textAlignment = .center;
            label.textColor = timeLabelTextColor
            if clockType == .none {
                
                label.text = ""
                
            } else if clockType == .arabic {
                
                label.text = clockType.timeLabelTitleList()[i]
                
            } else if clockType == .roman {
                
                label.text = ""
            }
            
            label.font = adjustFont(rect: label.frame)
            clockView.addSubview(label)
            let point = CGPoint(x: centerPoint.x + smallRadius * CGFloat(cosf(angle)),
                                y: centerPoint.y + smallRadius * CGFloat(sinf(angle)))
            label.center = point
            angle += Float(Double.pi/6)
        }
    }
    
    private func prepareHourHandLayer() {
        
        hourHandLayer = CAShapeLayer()
        guard let hourHandLayer = hourHandLayer else {
            
            return
        }
        
        guard let drawLayer = drawLayer else {
            
            return
        }
        hourHandLayer.frame = drawLayer.bounds
        drawLayer.addSublayer(hourHandLayer)
        hourHandLayer.strokeColor = hourHandColor.cgColor
        hourHandLayer.fillColor = UIColor.clear.cgColor
        
        let angle:Float = Float(Double.pi/2 + Double.pi)
        
        let radius:CGFloat = clockView.frame.width/2
        let length:CGFloat = radius * 0.6
        let centerPoint = CGPoint(x: radius, y: radius)
        
        let path = UIBezierPath()
        let point = CGPoint(x: centerPoint.x + length * CGFloat(cosf(angle)),
                            y: centerPoint.y + length * CGFloat(sinf(angle)))
        path.move(to: centerPoint)
        path.addLine(to: point)
        
        hourHandLayer.lineWidth = hourHandWidth
        hourHandLayer.path = path.cgPath
    }
    
    private func prepareMinuteHandLayer() {
        
        minuteHandLayer = CAShapeLayer()
        guard let minuteHandLayer = minuteHandLayer else {
            
            return
        }
        
        guard let drawLayer = drawLayer else {
            
            return
        }
        
        minuteHandLayer.frame = drawLayer.bounds
        drawLayer.addSublayer(minuteHandLayer)
        minuteHandLayer.strokeColor = minuteHandColor.cgColor
        minuteHandLayer.fillColor = UIColor.clear.cgColor
        
        let angle:Float = Float(Double.pi/2 + Double.pi)
        
        let radius:CGFloat = clockView.frame.width/2
        let length:CGFloat = radius * 0.8
        let centerPoint = CGPoint(x: radius, y: radius)
        
        let path = UIBezierPath()
        let point = CGPoint(x: centerPoint.x + length * CGFloat(cosf(angle)),
                            y: centerPoint.y + length * CGFloat(sinf(angle)))
        path.move(to: centerPoint)
        path.addLine(to: point)
        
        minuteHandLayer.lineWidth = minuteHandWidth
        minuteHandLayer.path = path.cgPath
    }
    
    private func preparePanGesture() {
        
        panMinuteLayer = CAShapeLayer()
        guard let panMinuteLayer = panMinuteLayer else {
            
            return
        }
        
        panHourLayer = CAShapeLayer()
        guard let panHourLayer = panHourLayer else {
            
            return
        }
        
        guard let drawLayer = drawLayer else {
            
            return
        }
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panAction(gesture:)))
        clockView.addGestureRecognizer(pan)
        let radius:CGFloat = clockView.frame.width/2
        let centerPoint = CGPoint(x: radius, y: radius)
        let smallRadius:CGFloat = 1000 * clockView.frame.width / 2930
        
        let path1 = UIBezierPath(ovalIn: CGRect(x: centerPoint.x - radius,
                                                y: centerPoint.y - radius,
                                                width: radius * 2,
                                                height: radius * 2))
        panMinuteLayer.frame = drawLayer.bounds
        drawLayer.insertSublayer(panMinuteLayer, at: 0)
        panMinuteLayer.strokeColor = UIColor.clear.cgColor
        panMinuteLayer.fillColor = clockColor.cgColor
        panMinuteLayer.path = path1.cgPath
        
        let path2 = UIBezierPath(ovalIn: CGRect(x: centerPoint.x - smallRadius,
                                                y: centerPoint.y - smallRadius,
                                                width: smallRadius * 2,
                                                height: smallRadius * 2))
        panHourLayer.frame = drawLayer.bounds
        drawLayer.addSublayer(panHourLayer)
        panHourLayer.strokeColor = UIColor.clear.cgColor//centerCircleLineColor.cgColor
        panHourLayer.fillColor = UIColor.clear.cgColor;
        panHourLayer.path = path2.cgPath
    }
    
    //MARK: Gesture Action
    @objc func panAction(gesture: UIPanGestureRecognizer) {
        
        
        guard let panMinuteLayer = panMinuteLayer else {
            
            return
        }
        
        guard let panHourLayer = panHourLayer else {
            
            return
        }
        
        let point = gesture.location(in: clockView)
        /// ジェスチャ開始
        if gesture.state == .began {
            print("began")
            /// 編集モードを設定
            if UIBezierPath(cgPath: panHourLayer.path!).contains(point) {
                
                editType = .hour
                startAngle = compensationHourAngle()
                /// 時間を設定
                editTimeHour(point: point)
                
            } else if UIBezierPath(cgPath: panMinuteLayer.path!).contains(point) {
                
                editType = .minute
                dateFormatter.dateFormat = AMCVDateFormat.minute.rawValue
                startAngle = caluculateAngle(minute: dateFormatter.string(from: currentDate))
                /// 分を設定
                editTimeMinute(point: point)
            } else {
                
                editType = .none
            }
            
        } else {
            print("else")
            if editType == .none {
                
                /// 編集モードを設定
                if UIBezierPath(cgPath: panHourLayer.path!).contains(point) {
                    
                    editType = .hour
                    startAngle = compensationHourAngle()
                    
                } else if UIBezierPath(cgPath: panMinuteLayer.path!).contains(point) {
                    
                    editType = .minute
                    dateFormatter.dateFormat = AMCVDateFormat.minute.rawValue
                    startAngle = caluculateAngle(minute: dateFormatter.string(from: currentDate))
                }
                
            } else if editType == .hour {
                
                /// 時間を設定
                editTimeHour(point: point)
                
            } else if editType == .minute {
                
                /// 分を設定
                editTimeMinute(point: point)
            }
        }
    }
    
    private func prepareTapGesture() {
        
        tapMinuteLayer = CAShapeLayer()
        guard let tapMinuteLayer = tapMinuteLayer else {

            return
        }

        tapHourLayer = CAShapeLayer()
        guard let tapHourLayer = tapHourLayer else {

            return
        }

        guard let drawLayer = drawLayer else {

            return
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapAction(gesture:)))
        clockView.addGestureRecognizer(tap)
        let radius:CGFloat = clockView.frame.width/2
        let centerPoint = CGPoint(x: radius, y: radius)
        let smallRadius:CGFloat = 1000 * clockView.frame.width / 2930

        let path1 = UIBezierPath(ovalIn: CGRect(x: centerPoint.x - radius,
                                                y: centerPoint.y - radius,
                                                width: radius * 2,
                                                height: radius * 2))
        tapMinuteLayer.frame = drawLayer.bounds
        drawLayer.insertSublayer(tapMinuteLayer, at: 0)
        tapMinuteLayer.strokeColor = UIColor.clear.cgColor
        tapMinuteLayer.fillColor = clockColor.cgColor
        tapMinuteLayer.path = path1.cgPath

        let path2 = UIBezierPath(ovalIn: CGRect(x: centerPoint.x - smallRadius,
                                                y: centerPoint.y - smallRadius,
                                                width: smallRadius * 2,
                                                height: smallRadius * 2))
        tapHourLayer.frame = drawLayer.bounds
        drawLayer.addSublayer(tapHourLayer)
        tapHourLayer.strokeColor = UIColor.clear.cgColor//centerCircleLineColor.cgColor
        tapHourLayer.fillColor = UIColor.clear.cgColor;
        tapHourLayer.path = path2.cgPath
    }
    
    //MARK: Gesture Action
    @objc func tapAction(gesture: UITapGestureRecognizer) {

        guard let tapMinuteLayer = tapMinuteLayer else {

            return
        }

        guard let tapHourLayer = tapHourLayer else {

            return
        }

        let point = gesture.location(in: clockView)
        /// 編集モードを設定
        if UIBezierPath(cgPath: tapHourLayer.path!).contains(point) {
            editType = .hour
            startAngle = compensationHourAngle()
            /// 時間を設定
            editTimeHour(point: point)
            
        } else
            
            if UIBezierPath(cgPath: tapMinuteLayer.path!).contains(point) {
                editType = .minute
                dateFormatter.dateFormat = AMCVDateFormat.minute.rawValue
                startAngle = caluculateAngle(minute: dateFormatter.string(from: currentDate))
                /// 分を設定
                editTimeMinute(point: point)
                
            } else {
                
                editType = .none
        }

    }
    
    private func editTimeHour(point: CGPoint) {
        
        let radian:Float = calculateRadian(point: point)
        var angle:Float = calculateHourAngle(radian: radian)
        dateFormatter.dateFormat = AMCVDateFormat.minute.rawValue
        let minute = Int(dateFormatter.string(from: currentDate))
        //angle += (Float(minute!)/60.0) * Float(Double.pi/6)
        endAngle = angle
        
        if startAngle == endAngle {
            
            return
        }
        
        var angleGap:Float = 0.0;
        if startAngle > endAngle {
            
            let gap = startAngle - endAngle
            let angle270 = Float(Double.pi/2) * 3
            if gap > angle270 {
                
                angleGap = (endAngle + Float(Double.pi*2)) - startAngle
                
            } else {
                
                angleGap = endAngle - startAngle
            }
            
        } else {
            
            let gap = endAngle - startAngle
            let angle270 = Float(Double.pi/2) * 3
            if gap > angle270 {
                
                angleGap = ((startAngle + Float(Double.pi*2)) - endAngle) * -1
                
            } else {
                
                angleGap = endAngle - startAngle
            }
        }
        
        var degree:Int = Int(angleGap*360 / Float(2*Double.pi))
        degree = (degree < 0) ? degree - 5 : degree + 5
        let hour:Int = degree/30
        
        drawHourHandLayer(angle: angle)
        
        currentDate = currentDate.addingTimeInterval(60 * 60 * TimeInterval(hour))
        
        changedTime()
        startAngle = angle
    }
    
    private func editTimeMinute(point: CGPoint) {
        
        let radian:Float = calculateRadian(point: point)
        let minute:Int = Int((radian - Float(Double.pi + Double.pi/2)) / (Float(Double.pi * 2)/60))
        dateFormatter.dateFormat = AMCVDateFormat.minute.rawValue
        if minute == Int(dateFormatter.string(from: currentDate)) {
            
            return
        }
        
        let angle:Float = caluculateMinuteAngle(radian: radian)
        endAngle = angle
        drawMinuteHandLayer(angle: angle)
        
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
        components.minute = minute
        currentDate = calendar.date(from: components)!
        
        if endAngle < startAngle {
            
            // 12時またぐ場合
            let gap = startAngle - endAngle
            let angle270 = Float(Double.pi/2) * 3
            if gap > angle270 {
                
                currentDate = currentDate.addingTimeInterval(60 * 60)// 1時間後
            }
            
        } else {
            
            // 12時またぐ場合
            let gap = endAngle - startAngle
            let angle270 = Float(Double.pi/2) * 3
            if gap > angle270 {
                
                currentDate = currentDate.addingTimeInterval(-60 * 60)// 1時間前
            }
        }
        
        //drawHourHandLayer(angle: compensationHourAngle())
        changedTime()
        
        startAngle = angle
    }
    
    //MARK: Calculate
    private func calculateHourAngle(radian: Float) -> Float {
        
        let hour = (radian - Float(Double.pi + Double.pi/2)) / (Float(Double.pi * 2)/12)
        let angle:Float = (Float(Double.pi * 2)/12) * Float(Int(hour))
        return  angle + Float(Double.pi + Double.pi/2)
    }
    
    private func caluculateMinuteAngle(radian: Float) -> Float {
        
        let minute = (radian - Float(Double.pi + Double.pi/2)) / (Float(Double.pi * 2)/60)
        let angle:Float = (Float(Double.pi * 2)/60) * Float(Int(minute))
        return  angle + Float(Double.pi + Double.pi/2)
    }
    
    private func calculateRadian(point: CGPoint) -> Float {
        
        // 原点　viewの中心
        let radius:CGFloat = clockView.frame.width/2
        let centerPoint = CGPoint(x: radius, y: radius)
        
        // 座標の差を求める 画面の上側をY座標＋とするので、Y座標は符号を入れ替える
        let x:Float = Float(point.x - centerPoint.x)
        let y:Float = -Float(point.y - centerPoint.y)
        // 角度radianを求める
        var radian: Float = atan2f(y, x)
        
        // radianに補正をする(3/2π~7/2π:0時が3/2π)
        radian = radian * -1
        if radian < 0 {
            
            radian += Float(Double.pi*2)
        }
        
        if radian >= 0 && radian < Float(Double.pi + Double.pi/2) {
            
            radian += Float(Double.pi*2)
        }
        return radian
    }
    
    private func caluculateAngle(minute: String) -> Float {
        
        let angle:Float = (Float(Double.pi*2)/60) * Float(minute)!
        return  angle + Float(Double.pi + Double.pi/2)
    }
    
    private func caluculateAngle(hour: String) -> Float {
        
        var hourInt:Int = Int(hour)!
        if hourInt > 12 {
            
            hourInt -= 12
        }
        
        let angle:Float = (Float(Double.pi*2)/12) * Float(hourInt)
        return  angle + Float(Double.pi + Double.pi/2)
    }
    
    private func compensationHourAngle() -> Float {
        
        dateFormatter.dateFormat = AMCVDateFormat.hour.rawValue
        var hourAngle:Float = caluculateAngle(hour: dateFormatter.string(from: currentDate))
        dateFormatter.dateFormat = AMCVDateFormat.minute.rawValue
        let minute:Int = Int(dateFormatter.string(from: currentDate))!
        //hourAngle += (Float(minute)/60.0) * Float(Double.pi/6)
        
        return hourAngle
    }
    
    private func adjustFont(rect: CGRect) -> UIFont {
        
        let length:CGFloat = (rect.width > rect.height) ? rect.height : rect.width
        let font = UIFont.systemFont(ofSize: length * 0.8)
        return font
    }
    
    //MARK: Draw Hand
    private func drawMinuteHandLayer(angle: Float) {
        
        if minuteHandImage != nil {
            
            let rotation = angle - Float(Double.pi/2 + Double.pi)
            minuteHandImageView.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
            return
        }
        
        guard let minuteHandLayer = minuteHandLayer else {
            
            return
        }
        
        let radius:CGFloat = clockView.frame.width/2
        let length:CGFloat = radius * 0.8
        let centerPoint = CGPoint(x: radius, y: radius)
        
        let path = UIBezierPath()
        let point = CGPoint(x: centerPoint.x + length * CGFloat(cosf(angle)),
                            y: centerPoint.y + length * CGFloat(sinf(angle)))
        path.move(to: centerPoint)
        path.addLine(to: point)
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        minuteHandLayer.path = path.cgPath
        CATransaction.commit()
    }
    
    private func drawHourHandLayer(angle: Float) {
        
        if hourHandImage != nil {
            
            clockImageView.image = clockImage
            minuteHandImageView.image = minuteHandImage
            hourHandImageView.image = hourHandImage
            let rotation = angle - Float(Double.pi/2 + Double.pi)
            hourHandImageView.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
            return
        }
        
        guard let hourHandLayer = hourHandLayer else {
            
            return
        }
        
        let radius:CGFloat = clockView.frame.width/2
        let length:CGFloat = radius * 0.6
        let centerPoint = CGPoint(x: radius, y: radius)
        
        let path = UIBezierPath()
        let point = CGPoint(x: centerPoint.x + length * CGFloat(cosf(angle)),
                            y: centerPoint.y + length * CGFloat(sinf(angle)))
        path.move(to: centerPoint)
        path.addLine(to: point)
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        hourHandLayer.path = path.cgPath
        CATransaction.commit()
    }
    
    //MARK:Shwo/Clear
    private func clear() {
        
        clockView.subviews.forEach{$0.removeFromSuperview()}
        selectedTimeLabel.removeFromSuperview()
        clockImageView.removeFromSuperview()
        hourHandImageView.removeFromSuperview()
        minuteHandImageView.removeFromSuperview()
        clockView.removeFromSuperview()
        drawLayer?.removeFromSuperlayer()
        minuteHandImageView.transform = CGAffineTransform.identity
        hourHandImageView.transform = CGAffineTransform.identity
        
        hourHandLayer = nil
        minuteHandLayer = nil
        panHourLayer = nil
        panMinuteLayer = nil
        drawLayer = nil
    }
    
    private func relodClock() {
        
        clear()
        
        prepareClockView()
        prepareClockImageViews()
        
        prepareDrawLayer()
        
        if clockImage == nil {
            
            prepareSmallClockIndexLayer()
            prepareClockIndexLayer()
            prepareTimeLabel()
        }
        
        preparePanGesture()
        prepareTapGesture()
        
        if hourHandImage == nil {
            
            prepareHourHandLayer()
        }
        
        if minuteHandImage == nil {
            
            prepareMinuteHandLayer()
        }
        
        prepareSelectedTimeLabel()
    }
    
    private func changedTime() {
        
        dateFormatter.dateFormat = AMCVDateFormat.time.rawValue
        selectedTimeLabel.text = dateFormatter.string(from: currentDate)
        
        if let delegate = delegate {
            
            delegate.clockView(clockView: self, didChangeDate: currentDate)
        }
    }
    
    public func redrawClock() {
        
        relodClock()
        
        dateFormatter.dateFormat = AMCVDateFormat.minute.rawValue
        drawMinuteHandLayer(angle: caluculateAngle(minute: dateFormatter.string(from: currentDate)))
        drawHourHandLayer(angle: compensationHourAngle())
        
        dateFormatter.dateFormat = AMCVDateFormat.time.rawValue
        selectedTimeLabel.text = dateFormatter.string(from: currentDate)
    }
}