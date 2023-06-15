//
//  AVPlayer+extension.swift
//  lono transistions
//
//  Created by Priyam Mehta on 15/06/23.
//

import Foundation
import AVKit

extension AVPlayer {
    func stop() {
        self.seek(to: CMTime.zero)
        self.pause()
    }
}
