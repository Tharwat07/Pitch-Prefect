import UIKit
import AVFoundation

extension PlaySoundViewController: AVAudioPlayerDelegate{
    
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisableTitle = "RecordingDisable"
        static let RecordingDisableMessage  = "you've disabled this app from recording microphone. Check setting"
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio recorder error"
        static let AudioSessionError = "Audio session error"
        static let AudioRecordingError = "Audio recording error"
        static let AudioFileError = "Audio file error"
        static let AudioEngineError = "Audio engine error"
    }
    enum PlayingState {case playing,notPlaying}
    
    func setupAudio (){
        do {
            audioFile = try AVAudioFile(forReading: recordedAudioURL as URL)
        }catch{
            showAlert(Alerts.AudioFileError, message: String(describing: error))
        }
    }
    
    func playSound(rate: Float? = nil,pitch: Float? = nil, echo : Bool = false , reverb : Bool = false){
        audioEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)
        
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changeRatePitchNode.rate = rate
        }
        audioEngine.attach(changeRatePitchNode)
        
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)
        
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)
        
        
        if echo == true && reverb == true {connectAudioNodes(audioPlayerNode,changeRatePitchNode,echoNode,reverbNode,audioEngine.outputNode)}
        else if echo == true {   connectAudioNodes(audioPlayerNode,changeRatePitchNode,echoNode,audioEngine.outputNode)}
        else if reverb == true {   connectAudioNodes(audioPlayerNode,changeRatePitchNode,reverbNode,audioEngine.outputNode)}
        else {connectAudioNodes(audioPlayerNode,changeRatePitchNode,audioEngine.outputNode)}
        
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, at: nil){
            var delayInSeconds: Double = 0
            if let lastRenderTime = self.audioPlayerNode.lastRenderTime,let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime){
                if let rate = rate {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double (self.audioFile.processingFormat.sampleRate) / Double (rate)
                }else{
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double (self.audioFile.processingFormat.sampleRate)}
            }
        
        
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(PlaySoundViewController.stopAudio),userInfo: nil,repeats: false)
            RunLoop.main.add(self.stopTimer!, forMode: .common)
        }
        
        do {
            try audioEngine.start()
        }catch {
            showAlert(Alerts.AudioEngineError,message: String(describing: error))
            return
        }
        audioPlayerNode.play()
    }
    
    @objc func stopAudio() {
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        configureUI(.notPlaying)
        if let audioEngine = audioEngine{
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    func connectAudioNodes(_ nodes: AVAudioNode...){
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }
    
    func configureUI(_ playState: PlayingState){
        switch (playState) {
        case .playing:
            setPlayButtonsEnabled(false)
            stopButton.isEnabled = true
        case .notPlaying:
            setPlayButtonsEnabled(true)
            stopButton.isEnabled = false
        }
    }
    
    func setPlayButtonsEnabled (_ enabled: Bool){
        fastButton.isEnabled = enabled
        slowButton.isEnabled = enabled
        highPitchButton.isEnabled = enabled
        lowPitchButton.isEnabled = enabled
        reverbButton.isEnabled = enabled
        echoButton.isEnabled = enabled
    }
    
    func showAlert(_ title: String,message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        self.present(alert , animated: true,completion: nil)
    }
    
}
