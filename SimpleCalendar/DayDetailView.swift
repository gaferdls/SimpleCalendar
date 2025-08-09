//
//  DayDetailView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/8/25.
//

import SwiftUI

struct DayDetailView: View {
    let selectedDay : Int
    
    var body: some View{
        Text("You selected day \(selectedDay)")
            .font(.title)
            .navigationTitle("Day \(selectedDay)")
    }
}

struct DayDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DayDetailView(selectedDay: 15)
    }
}
