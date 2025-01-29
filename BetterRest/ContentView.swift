//
//  ContentView.swift
//  BetterRest
//
//  Created by Варвара Уткина on 27.01.2025.
//

import CoreML
import SwiftUI

struct ContentView: View {
    @State private var wakeUp = defaultWakeTime
    @State private var sleepAmount = 8.0
    @State private var coffeeAmount = 1
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    @State private var idealBedTime = ""
    
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("When do you want to wake up?") {
                    DatePicker("Please enter a time", selection: $wakeUp, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .onChange(of: wakeUp) { _, _ in
                            calculateBedtime()
                        }
                }
                
                Section("Desired amount of sleep") {
                    Stepper("\(sleepAmount.formatted()) hours", value: $sleepAmount, in: 4...12, step: 0.25)
                        .onChange(of: sleepAmount) { _, _ in
                            calculateBedtime()
                        }
                }
                
                Section("Daily coffee intake") {
                    Picker("Coffee", selection: $coffeeAmount) {
                        ForEach(1...20, id: \.self) { cup in
                            Text("^[\(cup) cup](inflect: true)")
                        }
                    }
                    .onChange(of: coffeeAmount) { _, _ in
                        calculateBedtime()
                    }
                }
                
                Section("Your ideal bedtime is...") {
                    Text(idealBedTime)
                }
            }
            .navigationTitle("BetterRest")
            .toolbar {
                Button("Calculate", action: showAlert)
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear {
            calculateBedtime()
        }

    }
    
    func calculateBedtime() {
        do {
            let config = MLModelConfiguration()
            let model = try SleepCalculator(configuration: config)
            
            let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
            let hour = (components.hour ?? 0) * 60 * 60
            let minute = (components.minute ?? 0) * 60
            
            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: Double(coffeeAmount))
            
            let sleepTime = wakeUp - prediction.actualSleep
            
            alertTitle = "Your ideal bedtime is..."
            alertMessage = sleepTime.formatted(date: .omitted, time: .shortened)
            idealBedTime = alertMessage
        } catch {
            alertTitle = "Error"
            alertMessage = "Sorry, there was a problem calculating your bedtime."
            idealBedTime = alertMessage
        }
    }
    
    func showAlert() {
        calculateBedtime()
        showingAlert = true
    }
}

#Preview {
    ContentView()
}
