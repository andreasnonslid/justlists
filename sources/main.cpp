#include "imgui.h"
#include "GLFW/glfw3.h"
#include "backends/imgui_impl_glfw.h"
#include "backends/imgui_impl_opengl3.h"
#include <vector>
#include <string>
#include <cassert>
#include <fstream>
#include <iostream>
#include <numeric>
#include <unordered_map>
#include <functional>

enum class AppState { List, Filter, Edit, Exit };

struct App {
    AppState state = AppState::List;
    int selectedIndex = 0;
    std::string filterPattern;
    std::vector<std::string> list;
    std::vector<int> filteredIndices;
    std::vector<int> fullIndices;
    std::string tempEditBuffer;
    bool unsavedChanges = false;
};

App app;

void saveToFile() {
    std::ofstream outFile("list.list");
    if (!outFile) {
        std::cerr << "Error: Unable to save to file.\n";
        return;
    }
    for (const auto& item : app.list) {
        outFile << item << "\n";
    }
    outFile.close();
    app.unsavedChanges = false;
    std::cout << "List saved successfully to 'list.list'.\n";
}

void loadFromFile() {
    std::ifstream inFile("list.list");
    if (!inFile) {
        std::cerr << "Warning: Could not open file 'list.list'. Starting with an empty list.\n";
        return;
    }
    app.list.clear();
    std::string line;
    while (std::getline(inFile, line)) {
        if (!line.empty()) {
            app.list.push_back(line);
        }
    }
    inFile.close();
    app.fullIndices.resize(app.list.size());
    std::iota(app.fullIndices.begin(), app.fullIndices.end(), 0);
    std::cout << "Loaded " << app.list.size() << " items from 'list.list'.\n";
}

void updateFilteredIndices() {
    app.filteredIndices.clear();
    for (size_t i = 0; i < app.list.size(); ++i) {
        if (app.list[i].find(app.filterPattern) != std::string::npos) {
            app.filteredIndices.push_back(static_cast<int>(i));
        }
    }
}

void exitApp(GLFWwindow* window) {
    if (!app.unsavedChanges) {
        glfwSetWindowShouldClose(window, GLFW_TRUE);
    } else {
        app.state = AppState::Exit;
    }
}

void renderListView() {
    ImGui::Text("List:");
    const auto& indices = (app.state == AppState::Filter) ? app.filteredIndices : app.fullIndices;

    for (size_t i = 0; i < indices.size(); ++i) {
        int originalIndex = indices[i];
        ImGui::PushID(originalIndex);

        if (app.state == AppState::Edit && app.selectedIndex == originalIndex) {
            char buffer[256] = {};
            strncpy(buffer, app.tempEditBuffer.c_str(), sizeof(buffer));
            ImGui::SetKeyboardFocusHere();
            if (ImGui::InputText("##EditItem", buffer, sizeof(buffer), ImGuiInputTextFlags_AutoSelectAll)) {
                app.tempEditBuffer = buffer;
            }
            if (ImGui::IsKeyPressed(ImGuiKey_Enter)) {
                app.list[originalIndex] = app.tempEditBuffer;
                app.state = AppState::List;
                app.unsavedChanges = true;
            }
            if (ImGui::IsKeyPressed(ImGuiKey_Escape)) {
                app.state = AppState::List;
            }
        } else {
            if (ImGui::Selectable(app.list[originalIndex].c_str(), app.selectedIndex == originalIndex)) {
                if (app.state == AppState::List) {
                    app.selectedIndex = originalIndex;
                }
            }
        }

        ImGui::PopID();
    }
}

void renderFilterInput() {
    static bool isEditable = false; // Tracks the current state of the filter input's editability
    ImGui::Text("Fuzzy Filter:");

    char buffer[256] = {};
    strncpy(buffer, app.filterPattern.c_str(), sizeof(buffer));

    // Handle dynamic editability
    if (app.state == AppState::Filter && !isEditable) {
        ImGui::SetKeyboardFocusHere(); // Set keyboard focus when entering editable mode
        isEditable = true;
    } else if (app.state != AppState::Filter && isEditable) {
        isEditable = false;
    }

    // Render filter input based on editability
    if (isEditable) {
        if (ImGui::InputText("##Filter", buffer, sizeof(buffer))) {
            app.filterPattern = buffer;
            updateFilteredIndices();
            std::cout << "FILTER WITH: " << app.filterPattern << "\n";
        }
    } else {
        ImGui::TextDisabled("%s", app.filterPattern.c_str());
    }
}

void renderBottomBar() {
    ImGui::Separator();
    switch (app.state) {
        case AppState::List:
            ImGui::Text("a: Add | e: Edit | d: Delete | f: Filter | s: Save | x: Exit");
            break;
        case AppState::Filter:
            ImGui::Text("Enter: Return to List | x: Exit");
            break;
        case AppState::Edit:
            ImGui::Text("Enter: Confirm | Escape: Cancel | x: Exit");
            break;
        case AppState::Exit:
            ImGui::Text("Enter: Confirm Exit | s: Save and Exit | Escape: Cancel");
            break;
    }
}

void handleKeyInput(GLFWwindow* window) {
    // Map for actions based on the current state
    static const std::unordered_map<AppState, std::unordered_map<ImGuiKey, std::function<void()>>> stateKeyActions = {
        { AppState::List, {
            { ImGuiKey_A, [] {
                app.list.emplace_back("New Item");
                app.selectedIndex = app.list.size() - 1;
                app.state = AppState::Edit;
                app.tempEditBuffer = app.list[app.selectedIndex];
                std::cout << "Switched to Edit State (New Item).\n";
            }},
            { ImGuiKey_E, [] {
                if (app.selectedIndex >= 0 && app.selectedIndex < static_cast<int>(app.list.size())) {
                    app.state = AppState::Edit;
                    app.tempEditBuffer = app.list[app.selectedIndex];
                    std::cout << "Switched to Edit State (Editing Item).\n";
                }
            }},
            { ImGuiKey_D, [] {
                if (app.selectedIndex >= 0 && app.selectedIndex < static_cast<int>(app.list.size())) {
                    app.list.erase(app.list.begin() + app.selectedIndex);
                    if (app.selectedIndex >= static_cast<int>(app.list.size())) app.selectedIndex--;
                    app.unsavedChanges = true;
                    std::cout << "Deleted Item. Updated List.\n";
                }
            }},
            { ImGuiKey_F, [] {
                app.state = AppState::Filter;
                app.filterPattern.clear();
                updateFilteredIndices();
                std::cout << "Switched to Filter State.\n";
            }},
            { ImGuiKey_S, [] { saveToFile(); }},
            { ImGuiKey_X, [&] { exitApp(window); }}
        }},
        { AppState::Filter, {
            { ImGuiKey_Enter, [] {
                app.state = AppState::List;
                std::cout << "Filter Complete. Returning to List State.\n";
            }},
            { ImGuiKey_X, [&] { exitApp(window); }}
        }},
        { AppState::Exit, {
            { ImGuiKey_Enter, [&] {
                glfwSetWindowShouldClose(window, GLFW_TRUE);
                std::cout << "Exiting without saving.\n";
            }},
            { ImGuiKey_S, [&] {
                saveToFile();
                glfwSetWindowShouldClose(window, GLFW_TRUE);
                std::cout << "Saving and exiting.\n";
            }},
            { ImGuiKey_Escape, [] {
                app.state = AppState::List;
                std::cout << "Exit canceled. Returning to List State.\n";
            }}
        }}
    };

    // Navigation Keys for List State
    static const std::unordered_map<ImGuiKey, std::function<void()>> navigationKeys = {
        { ImGuiKey_UpArrow, [] {
            if (app.selectedIndex > 0) app.selectedIndex--;
        }},
        { ImGuiKey_DownArrow, [] {
            if (app.selectedIndex < static_cast<int>(app.list.size()) - 1) app.selectedIndex++;
        }},
        { ImGuiKey_LeftArrow, [] { app.selectedIndex = 0; }}, // Go to the first item
        { ImGuiKey_RightArrow, [] { app.selectedIndex = static_cast<int>(app.list.size()) - 1; }}, // Go to the last item
        { ImGuiKey_K, [] {
            if (app.selectedIndex > 0) app.selectedIndex--;
        }},
        { ImGuiKey_J, [] {
            if (app.selectedIndex < static_cast<int>(app.list.size()) - 1) app.selectedIndex++;
        }},
        { ImGuiKey_H, [] { app.selectedIndex = 0; }}, // Go to the first item
        { ImGuiKey_L, [] { app.selectedIndex = static_cast<int>(app.list.size()) - 1; }} // Go to the last item
    };

    // Execute key actions for the current state
    auto stateActions = stateKeyActions.find(app.state);
    if (stateActions != stateKeyActions.end()) {
        for (const auto& [key, action] : stateActions->second) {
            if (ImGui::IsKeyPressed(key)) {
                action(); // Execute the action
                return;
            }
        }
    }

    // Handle navigation keys in List State
    if (app.state == AppState::List) {
        for (const auto& [key, action] : navigationKeys) {
            if (ImGui::IsKeyPressed(key)) {
                action(); // Execute navigation action
                return;
            }
        }
    }

    // Default: Handle unknown state
    if (app.state != AppState::List && app.state != AppState::Edit && app.state != AppState::Filter && app.state != AppState::Exit) {
        std::cerr << "Unknown state detected! Exiting app for safety.\n";
        std::cerr << "State Dump: " << static_cast<int>(app.state) << "\n";
        glfwSetWindowShouldClose(window, GLFW_TRUE);
    }
}

int main() {
    assert(glfwInit());
    GLFWwindow* window = glfwCreateWindow(800, 600, "justlists", nullptr, nullptr);
    assert(window);
    glfwMakeContextCurrent(window);

    ImGui::CreateContext();
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");

    loadFromFile();

    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        int display_w, display_h;
        glfwGetFramebufferSize(window, &display_w, &display_h);
        ImGui::SetNextWindowPos(ImVec2(0, 0));
        ImGui::SetNextWindowSize(ImVec2(display_w, display_h));

        handleKeyInput(window);

        ImGui::Begin("justlists", nullptr, ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoMove);
        ImGui::BeginChild("TopSection", ImVec2(0, -70), false);

        renderListView();

        ImGui::EndChild();
        renderFilterInput();
        renderBottomBar();
        ImGui::End();

        ImGui::Render();
        glViewport(0, 0, display_w, display_h);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
        glfwSwapBuffers(window);
    }

    saveToFile();

    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
    glfwDestroyWindow(window);
    glfwTerminate();
    return 0;
}
