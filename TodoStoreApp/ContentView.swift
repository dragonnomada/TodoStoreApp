//
//  ContentView.swift
//  TodoStoreApp
//
//  Created by Alan Badillo Salas on 15/05/23.
//

import SwiftUI
import TodoStore
import Combine

extension TodoStore {
    var checkedTodos: [TodoItem] {
        get {
            todos.filter { todo in
                todo.checked
            }
        }
        set {
            newValue.filter({ todo in
                !todo.checked
            }).forEach { todo in
                DispatchQueue.main.async {
                    [weak self] in
                    let _ = try? self?.editTodo(withId: todo.id, title: todo.title, checked: todo.checked)
                }
            }
        }
    }
    var uncheckedTodos: [TodoItem] {
        get {
            todos.filter { todo in
                !todo.checked
            }
        }
        set {
            print("Unchecked todos:")
            print(newValue)
            newValue.filter({ todo in
                todo.checked
            }).forEach { todo in
                print("Updating unchecked:")
                print(todo)
                DispatchQueue.main.async {
                    [weak self] in
                    let _ = try? self?.editTodo(withId: todo.id, title: todo.title, checked: todo.checked)
                }
            }
        }
    }
}

struct TodoDetails: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @StateObject var todoStore: TodoStore
    @Binding var todo: TodoItem
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Text(todo.checked ? "✅" : "⭕️")
                
                Spacer()
                
                VStack(alignment: .center) {
                    TextField("Todo Title", text: $todo.title)
                }
                
                Spacer()
                
//                                        Toggle("", isOn: Binding(get: {
//                                            todo.checked
//                                        }, set: { value in
//                                            DispatchQueue.main.async {
//                                                let _ = try? todoStore.editTodo(withId: todo.id, title: todo.title, checked: value)
//                                            }
//                                        }))
                Toggle("", isOn: Binding(get: {
                    todo.checked
                }, set: { value in
                    todo.checked = value
                    DispatchQueue.main.async {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }))
                    .frame(maxWidth: 60)
                //                                Toggle("", isOn: Binding(get: {
                //                                    todo.checked
                //                                }, set: { value, _ in
                //                                    let _ = try? todoStore.editTodo(withId: todo.id, title: nil, checked: value)
                //                                }))
            }
            .padding()
            
            HStack {
                Text("Create at:")
                VStack(alignment: .leading) {
                    Text(todo.createAt, style: .date)
                    Text(todo.createAt, style: .time)
                }
                if let updateAt = todo.updateAt {
                    Spacer()
                    Divider()
                    Spacer()
                    Text("Update at:")
                    VStack(alignment: .leading) {
                        Text(updateAt, style: .date)
                        Text(updateAt, style: .time)
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxHeight: 80)
            .padding()
            
            Spacer()
            
            HStack() {
                Button {
                    todoStore.todos.append(todo.copy())
                    DispatchQueue.main.async {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                
                Button {
                    let _ = try? todoStore.removeTodo(withId: todo.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            Spacer()
        }
    }
    
}

struct ContentView: View {
    @EnvironmentObject var todoStore: TodoStore
    
    @State var title = ""
    
    @State var cancellable: AnyCancellable? = nil
    
    @State var isLoaded = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Todo Title", text: $title)
                    Button {
                        let _ = todoStore.addTodo(withTitle: title)
                        title = ""
                    } label: {
                        Label("Add", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }
                }
                .padding()
                
                List {
                    Section(header: Text("Not Completed")) {
                        if todoStore.uncheckedTodos.count == 0 {
                            Text("There are any Todo")
                                .font(.callout)
                                .italic()
                                .foregroundColor(.secondary)
                        }
                        ForEach($todoStore.uncheckedTodos) { $todo in
                            NavigationLink {
                                TodoDetails(
                                    todoStore: todoStore,
                                    todo: Binding(
                                        get: {
                                            todo.copy(keepId: true, withCreation: true, withUpdating: true)
                                        },
                                        set: { updatedTodo in
                                            print("UpdateTodo (Unchecked):")
                                            print(updatedTodo)
                                            DispatchQueue.main.async {
                                                let _ = try? todoStore.editTodo(withId: updatedTodo.id, title: updatedTodo.title, checked: updatedTodo.checked)
                                            }
                                        }
                                    )
                                )
                            } label: {
                                HStack {
                                    Text(todo.checked ? "✅" : "⭕️")
                                    
                                    VStack(alignment: .center) {
                                        Text(todo.title)
                                            .strikethrough(todo.checked, color: .blue)
                                        
                                        HStack {
                                            Text(todo.createAt, style: .time)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $todo.checked)
                                    //                            Toggle("", isOn: Binding(get: {
                                    //                                todo.checked
                                    //                            }, set: { value, _ in
                                    //                                let _ = try? todoStore.editTodo(withId: todo.id, title: nil, checked: value)
                                    //                            }))
                                    
                                    //                            Button {
                                    //                                let _ = try? todoStore.removeTodo(withId: todo.id)
                                    //                            } label: {
                                    //                                Label("Delete", systemImage: "trash")
                                    //                                    .labelStyle(.iconOnly)
                                    //                            }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                let todo = todoStore.uncheckedTodos[index]
                                
                                DispatchQueue.main.async {
                                    let _ = try? todoStore.removeTodo(withId: todo.id)
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Completed")) {
                        if todoStore.checkedTodos.count == 0 {
                            Text("There are any Todo")
                                .font(.callout)
                                .italic()
                                .foregroundColor(.secondary)
                        }
                        //                        ForEach(Binding(get: {
                        //                            todoStore.checkedTodos
                        //                        }, set: { value, _ in
                        //                            DispatchQueue.main.async {
                        //                                value.forEach { todo in
                        //                                    let _ = try? todoStore.editTodo(withId: todo.id, title: todo.title, checked: todo.checked)
                        //                                }
                        //                            }
                        //                        }))
                        ForEach($todoStore.checkedTodos) { $todo in
                            NavigationLink {
                                TodoDetails(
                                    todoStore: todoStore,
                                    todo: Binding(
                                        get: {
                                            todo.copy(keepId: true, withCreation: true, withUpdating: true)
                                        },
                                        set: { updatedTodo in
                                            print("UpdateTodo (Checked):")
                                            print(updatedTodo)
                                            DispatchQueue.main.async {
                                                let _ = try? todoStore.editTodo(withId: updatedTodo.id, title: updatedTodo.title, checked: updatedTodo.checked)
                                            }
                                        }
                                    )
                                )
                            } label: {
                                HStack {
                                    Text(todo.checked ? "✅" : "⭕️")
                                    
                                    VStack(alignment: .center) {
                                        Text(todo.title)
                                            .strikethrough(todo.checked, color: .blue)
                                        
                                        HStack {
                                            Text(todo.createAt, style: .time)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $todo.checked)
                                    //                            Toggle("", isOn: Binding(get: {
                                    //                                todo.checked
                                    //                            }, set: { value, _ in
                                    //                                let _ = try? todoStore.editTodo(withId: todo.id, title: nil, checked: value)
                                    //                            }))
                                    
                                    //                            Button {
                                    //                                let _ = try? todoStore.removeTodo(withId: todo.id)
                                    //                            } label: {
                                    //                                Label("Delete", systemImage: "trash")
                                    //                                    .labelStyle(.iconOnly)
                                    //                            }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                let todo = todoStore.checkedTodos[index]
                                
                                DispatchQueue.main.async {
                                    let _ = try? todoStore.removeTodo(withId: todo.id)
                                }
                            }
                        }
                    }
                }
                
                
            }
            .onAppear {
                cancellable = todoStore.$todos.sink { todos in
                    print("Todos:")
                    print(todos.map({ todo in
                        todo.title
                    }))
                    print("CheckedTodos:")
                    print(todoStore.checkedTodos.map({ todo in
                        todo.title
                    }))
                    print("UncheckedTodos:")
                    print(todoStore.uncheckedTodos.map({ todo in
                        todo.title
                    }))
                }
                
                if !isLoaded {
                    let firstTodo = todoStore.addTodo(withTitle: "Sample 1")
                    
                    print(firstTodo)
                    
                    let secondTodo = todoStore.addTodo(withTitle: "Sample 2")
                    
                    print(secondTodo)
                    
                    let _ = try? todoStore.editTodo(withId: secondTodo.id, title: nil, checked: true)
                    
                    isLoaded = true
                }
            }
            .onDisappear {
                cancellable?.cancel()
                cancellable = nil
            }
            .padding()
            .toolbar {
                EditButton()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(TodoStore())
    }
}
