//
//  ContentView.swift
//  Test_App
//
//  Created by Arpita  Pradhan on 12/4/25.
//

import SwiftUI
import UserNotifications

struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var dueDate: Date? = nil
}
extension Task {
    var isOverdue: Bool {
        if let dueDate = dueDate {
            return !isCompleted && dueDate < Date()
        }
        return false
    }
}

struct ContentView: View {
    @State private var tasks: [Task] = []
    @State private var newTask: String = ""
    @State private var showAlert = false
    
    @State private var editingTask: Task?
    @State private var editedText: String = ""
    @State private var showEditSheet = false
    
    @State private var selectedDate = Date()
    @State private var editedDate = Date()

    var body: some View {
        
        NavigationView {
            
            VStack {
//                HStack {
//                    TextField("Enter task", text: $newTask)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//
//                    Button("Add") {
//                        if newTask.trimmingCharacters(in: .whitespaces).isEmpty {
//                            showAlert = true
//                        }
//                        else {
//                            
//                            let task = Task(title: newTask, isCompleted: false, dueDate: selectedDate)
//                            tasks.append(task)
//                            newTask = ""
//                            saveTasks()
//                        }
//                    }
//                    DatePicker("Select Due Date", selection: $selectedDate, displayedComponents: .date)
//                        .padding()
//                }
//                .padding()
                
                HStack(spacing: 8) {
                    
                    // TextField
                    TextField("Enter task", text: $newTask)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)

                    // Compact DatePicker (key fix)
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact) // ✅ important
                    
                    // Add Button
                    Button(action: {
                        if newTask.trimmingCharacters(in: .whitespaces).isEmpty {
                            showAlert = true
                        } else {
                            let task = Task(title: newTask, isCompleted: false, dueDate: selectedDate)
                            tasks.append(task)
                            saveTasks()
                            updateAppBadge()
                            scheduleNotification(for: task)
                            newTask = ""
                            
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)

                List {
                    ForEach(tasks) { task in
                            HStack {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .onTapGesture {
                                        toggleTask(task)
                                    }
                                Text(task.title)
                                        .strikethrough(task.isCompleted)
                                        .foregroundColor(task.isOverdue ? .red : (task.isCompleted ? .gray : .black))
                                        .onTapGesture {
                                        showUpdateSheet(for: task)
                                        }
                                    if let dueDate = task.dueDate {
                                        Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(task.isOverdue ? .red : .gray)
                                            .onTapGesture {
                                                showUpdateSheet(for: task)
                                            }
                                        
                                    }
                                
                                    
                                
//                                Text(task.title)
//                                    .strikethrough(task.isCompleted)
//                                    .foregroundColor(task.isCompleted ? .gray : .black)
                                    
                            }
                        }
                        .onDelete(perform: deleteTask)
                }
            }
            
            .onAppear {
             print("DetailView appeared!") // Code runs when DetailView becomes visible
                loadTasks()
                requestNotificationPermission()
             }
            
            .alert("Empty Task", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a task before adding.")
            }
            
            .sheet(isPresented: $showEditSheet) {
                VStack {
                    Text("Edit Task")
                        .font(.headline)

                    TextField("Edit task", text: $editedText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    DatePicker("Update Due Date", selection: $editedDate, displayedComponents: [.date, .hourAndMinute])
                        .padding()

                    Button("Save") {
                        updateTask()
                        showEditSheet = false
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("To-Do List")
        }
    }
    
    func toggleTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()

            if tasks[index].isCompleted {
            removeNotification(for: tasks[index])
            } else {
            scheduleNotification(for: tasks[index])
            }
            saveTasks()
            updateAppBadge()
        }
    }
    func showUpdateSheet(for task: Task){
        editingTask = task
        editedText = task.title
        editedDate = task.dueDate ?? Date() // load existing date
        showEditSheet = true
    }
    func loadTasks() {
        if let savedData = UserDefaults.standard.data(forKey: "tasks"),
              let decoded = try? JSONDecoder().decode([Task].self, from: savedData) {
               tasks = decoded
           }
        
//        if let savedTasks = UserDefaults.standard.stringArray(forKey: "tasks") {
//            tasks = savedTasks
//            print("Task", tasks)
//        }
    }
    func updateTask() {
        
        if let editingTask = editingTask,
           let index = tasks.firstIndex(where: { $0.id == editingTask.id }) {
            // Remove old notification
            removeNotification(for: tasks[index])
            
            // Update data
            tasks[index].title = editedText
            tasks[index].dueDate = editedDate
            
            // Schedule new notification
             scheduleNotification(for: tasks[index])

            saveTasks()
            updateAppBadge()
        }
    }
    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        saveTasks()
        updateAppBadge()
    }
    func saveTasks() {
        //UserDefaults.standard.set(tasks, forKey: "tasks")
        if let encoded = try? JSONEncoder().encode(tasks) {
        UserDefaults.standard.set(encoded, forKey: "tasks")
        }
    }
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notifications allowed")
            } else {
                print("Notifications denied")
            }
        }
    }
    func removeNotification(for task: Task) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
    func scheduleNotification(for task: Task) {
        guard let dueDate = task.dueDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification Error: \(error.localizedDescription)")
            }
        }
    }
    func updateAppBadge() {
        let overdueCount = tasks.filter {
            !$0.isCompleted &&
            ($0.dueDate ?? Date()) < Date()
        }.count

        UIApplication.shared.applicationIconBadgeNumber = overdueCount
    }
}
