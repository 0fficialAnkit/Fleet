import os
import matplotlib.pyplot as plt
import matplotlib.patches as patches

os.makedirs('./Internship_report_and_ppt/assets', exist_ok=True)

# 1. System Architecture
def create_architecture_diagram():
    fig, ax = plt.subplots(figsize=(10, 6.5), dpi=300)
    ax.axis('off')
    
    # Background card
    fig.patch.set_facecolor('#F8FAFC')
    ax.set_facecolor('#F8FAFC')
    
    # Layer 1: Presentation Layer
    p1 = patches.FancyBboxPatch((0.5, 6.8), 9.0, 2.2, boxstyle="round,pad=0.2", fc="#EFF6FF", ec="#3B82F6", lw=2)
    ax.add_patch(p1)
    ax.text(5.0, 8.6, "PRESENTATION LAYER (SwiftUI 5.0 / iOS 17+)", ha='center', va='center', fontsize=12, fontweight='bold', color='#1E40AF')
    
    # Presentation Components
    comp_views = [
        ("Fleet Manager Views\n(Dashboard, Orders, Analytics)", 1.8),
        ("Driver Views\n(Trips, Geofencing, Fuel OCR)", 5.0),
        ("Maintenance Views\n(Scheduler, Work Orders)", 8.2)
    ]
    for text, x in comp_views:
        rect = patches.FancyBboxPatch((x-1.3, 7.0), 2.6, 1.2, boxstyle="round,pad=0.1", fc="#FFFFFF", ec="#93C5FD", lw=1.5)
        ax.add_patch(rect)
        ax.text(x, 7.6, text, ha='center', va='center', fontsize=8.5, color='#1E3A8A', multialignment='center')

    # Arrow 1 to 2
    ax.annotate('', xy=(5.0, 6.4), xytext=(5.0, 6.8), arrowprops=dict(arrowstyle="<->", color="#4B5563", lw=2))

    # Layer 2: Business Logic & State Layer
    p2 = patches.FancyBboxPatch((0.5, 3.8), 9.0, 2.3, boxstyle="round,pad=0.2", fc="#F0FDF4", ec="#10B981", lw=2)
    ax.add_patch(p2)
    ax.text(5.0, 5.75, "BUSINESS LOGIC & STATE LAYER (MVVM + Observation)", ha='center', va='center', fontsize=12, fontweight='bold', color='#065F46')
    
    comp_vm = [
        ("AuthViewModel\n(2FA, RBAC, Sessions)", 1.8),
        ("Service ViewModels\n(Vehicles, Trips, Orders)", 5.0),
        ("Realtime & Managers\n(WebSockets, CoreLocation)", 8.2)
    ]
    for text, x in comp_vm:
        rect = patches.FancyBboxPatch((x-1.3, 4.0), 2.6, 1.3, boxstyle="round,pad=0.1", fc="#FFFFFF", ec="#6EE7B7", lw=1.5)
        ax.add_patch(rect)
        ax.text(x, 4.65, text, ha='center', va='center', fontsize=8.5, color='#047857', multialignment='center')

    # Arrow 2 to 3
    ax.annotate('', xy=(5.0, 3.4), xytext=(5.0, 3.8), arrowprops=dict(arrowstyle="<->", color="#4B5563", lw=2))

    # Layer 3: Backend-as-a-Service (Supabase Cloud)
    p3 = patches.FancyBboxPatch((0.5, 0.6), 9.0, 2.5, boxstyle="round,pad=0.2", fc="#FAF5FF", ec="#8B5CF6", lw=2)
    ax.add_patch(p3)
    ax.text(5.0, 2.75, "BACKEND CLOUD SERVICES (Supabase BaaS / PostgreSQL 15)", ha='center', va='center', fontsize=12, fontweight='bold', color='#5B21B6')
    
    comp_baas = [
        ("Supabase Auth\n(JWT, 2FA OTP, RBAC)", 1.6),
        ("PostgreSQL Relational DB\n(Users, Vehicles, Trips)", 3.9),
        ("Realtime Engine\n(WebSocket Pub-Sub)", 6.2),
        ("Storage & Edge Functions\n(Bills, Notifications)", 8.4)
    ]
    for text, x in comp_baas:
        rect = patches.FancyBboxPatch((x-0.95, 0.85), 1.9, 1.4, boxstyle="round,pad=0.1", fc="#FFFFFF", ec="#C4B5FD", lw=1.5)
        ax.add_patch(rect)
        ax.text(x, 1.55, text, ha='center', va='center', fontsize=7.8, color='#4C1D95', multialignment='center')

    ax.set_xlim(0, 10)
    ax.set_ylim(0, 9.5)
    plt.tight_layout()
    plt.savefig('./Internship_report_and_ppt/assets/system_architecture.png', dpi=300, facecolor=fig.get_facecolor(), edgecolor='none')
    plt.close()

# 2. DFD Level 0 (Context Diagram)
def create_dfd_level0():
    fig, ax = plt.subplots(figsize=(9, 5.5), dpi=300)
    ax.axis('off')
    fig.patch.set_facecolor('#F8FAFC')
    ax.set_facecolor('#F8FAFC')

    # Central Process
    circ = patches.Circle((4.5, 2.8), 1.3, fc="#DBEAFE", ec="#2563EB", lw=2.5)
    ax.add_patch(circ)
    ax.text(4.5, 3.0, "0.0\nKAFILA SMART\nFLEET SYSTEM", ha='center', va='center', fontsize=11, fontweight='bold', color='#1E40AF')

    # Entities
    entities = [
        ("Fleet Manager\n(Admin)", 1.2, 4.3, "#FEF3C7", "#D97706"),
        ("Driver\n(Mobile App)", 1.2, 1.3, "#DCFCE7", "#16A34A"),
        ("Maintenance Staff\n(Technician)", 7.8, 1.3, "#FFEDD5", "#EA580C"),
        ("Supabase BaaS\n(Cloud Database)", 7.8, 4.3, "#F3E8FF", "#9333EA")
    ]
    for name, x, y, bg, border in entities:
        rect = patches.FancyBboxPatch((x-1.0, y-0.6), 2.0, 1.2, boxstyle="round,pad=0.1", fc=bg, ec=border, lw=2)
        ax.add_patch(rect)
        ax.text(x, y, name, ha='center', va='center', fontsize=9.5, fontweight='bold', color='#1F2937', multialignment='center')

    # Flows
    ax.annotate("Vehicle/Driver\nAssignments", xy=(3.3, 3.4), xytext=(2.2, 4.3),
                arrowprops=dict(arrowstyle="->", color="#374151", lw=1.5), fontsize=8, color="#374151")
    ax.annotate("Trip Status, Telemetry,\nFuel Receipts", xy=(3.4, 2.4), xytext=(2.2, 1.4),
                arrowprops=dict(arrowstyle="->", color="#374151", lw=1.5), fontsize=8, color="#374151")
    ax.annotate("Work Orders &\nDefect Fixes", xy=(5.6, 2.4), xytext=(6.7, 1.4),
                arrowprops=dict(arrowstyle="<-", color="#374151", lw=1.5), fontsize=8, color="#374151")
    ax.annotate("Auth, Realtime Data,\nPostgreSQL Sync", xy=(5.6, 3.4), xytext=(6.7, 4.3),
                arrowprops=dict(arrowstyle="<->", color="#374151", lw=1.5), fontsize=8, color="#374151")

    ax.set_xlim(0, 9)
    ax.set_ylim(0, 5.5)
    plt.tight_layout()
    plt.savefig('./Internship_report_and_ppt/assets/dfd_level0.png', dpi=300, facecolor=fig.get_facecolor(), edgecolor='none')
    plt.close()

# 3. DFD Level 1
def create_dfd_level1():
    fig, ax = plt.subplots(figsize=(10, 6.5), dpi=300)
    ax.axis('off')
    fig.patch.set_facecolor('#F8FAFC')
    ax.set_facecolor('#F8FAFC')

    # 4 Main Processes
    procs = [
        ("1.0 Authentication\n& 2FA OTP Service", 2.0, 5.0, "#DBEAFE", "#2563EB"),
        ("2.0 Vehicle Fleet\n& Asset Management", 5.0, 5.0, "#DCFCE7", "#16A34A"),
        ("3.0 Trip Dispatch &\nRoute Tracking", 2.0, 2.0, "#FEF3C7", "#D97706"),
        ("4.0 Maintenance &\nDefect Reporting", 5.0, 2.0, "#FFEDD5", "#EA580C"),
        ("5.0 Fuel & Expense\nAnalytics (OCR)", 8.0, 3.5, "#F3E8FF", "#9333EA")
    ]
    for text, x, y, bg, border in procs:
        circ = patches.Circle((x, y), 0.95, fc=bg, ec=border, lw=2)
        ax.add_patch(circ)
        ax.text(x, y, text, ha='center', va='center', fontsize=8, fontweight='bold', color='#111827', multialignment='center')

    # Data Stores
    stores = [
        ("D1: Users & Roles DB", 2.0, 3.5),
        ("D2: Vehicles & Trips DB", 5.0, 3.5),
        ("D3: Maintenance Tasks DB", 3.5, 0.7),
        ("D4: Fuel Receipts & Logs DB", 7.5, 1.2)
    ]
    for text, x, y in stores:
        rect = patches.Rectangle((x-1.1, y-0.3), 2.2, 0.6, fc="#FFFFFF", ec="#4B5563", lw=1.5)
        ax.add_patch(rect)
        ax.text(x, y, text, ha='center', va='center', fontsize=7.5, fontweight='bold', color='#374151')

    # Connectors
    ax.annotate("", xy=(2.0, 4.05), xytext=(2.0, 3.8), arrowprops=dict(arrowstyle="->", color="#4B5563", lw=1.5))
    ax.annotate("", xy=(5.0, 4.05), xytext=(5.0, 3.8), arrowprops=dict(arrowstyle="->", color="#4B5563", lw=1.5))
    ax.annotate("", xy=(2.0, 2.95), xytext=(2.0, 3.2), arrowprops=dict(arrowstyle="<-", color="#4B5563", lw=1.5))
    ax.annotate("", xy=(5.0, 2.95), xytext=(5.0, 3.2), arrowprops=dict(arrowstyle="<->", color="#4B5563", lw=1.5))
    ax.annotate("", xy=(7.05, 3.5), xytext=(5.95, 3.5), arrowprops=dict(arrowstyle="<->", color="#4B5563", lw=1.5))
    ax.annotate("", xy=(4.5, 1.5), xytext=(3.5, 1.0), arrowprops=dict(arrowstyle="->", color="#4B5563", lw=1.5))

    ax.set_xlim(0.5, 9.5)
    ax.set_ylim(0.2, 6.5)
    plt.tight_layout()
    plt.savefig('./Internship_report_and_ppt/assets/dfd_level1.png', dpi=300, facecolor=fig.get_facecolor(), edgecolor='none')
    plt.close()

# 4. UML Use Case Diagram
def create_uml_usecase():
    fig, ax = plt.subplots(figsize=(10, 6.5), dpi=300)
    ax.axis('off')
    fig.patch.set_facecolor('#F8FAFC')
    ax.set_facecolor('#F8FAFC')

    # System Boundary
    box = patches.FancyBboxPatch((2.2, 0.4), 5.6, 5.7, boxstyle="round,pad=0.2", fc="#FFFFFF", ec="#374151", lw=2)
    ax.add_patch(box)
    ax.text(5.0, 5.85, "Kafila Fleet Management iOS System", ha='center', va='center', fontsize=11, fontweight='bold', color='#111827')

    # Actors
    actors = [
        ("Fleet\nManager", 1.0, 4.5, "#2563EB"),
        ("Driver", 1.0, 2.0, "#16A34A"),
        ("Maintenance\nEngineer", 9.0, 3.2, "#D97706")
    ]
    for name, x, y, col in actors:
        # stick figure head
        head = patches.Circle((x, y+0.4), 0.22, fc=col, ec="#111827", lw=1.5)
        ax.add_patch(head)
        # body & arms
        ax.plot([x, x], [y+0.18, y-0.2], color="#111827", lw=2)
        ax.plot([x-0.25, x+0.25], [y+0.05, y+0.05], color="#111827", lw=2)
        ax.plot([x, x-0.2], [y-0.2, y-0.5], color="#111827", lw=2)
        ax.plot([x, x+0.2], [y-0.2, y-0.5], color="#111827", lw=2)
        ax.text(x, y-0.75, name, ha='center', va='center', fontsize=9, fontweight='bold', color=col, multialignment='center')

    # Use Cases
    use_cases = [
        ("Authenticate via 2FA OTP & RBAC", 5.0, 5.2),
        ("Monitor Live Fleet Telemetry & Geofences", 5.0, 4.3),
        ("Assign & Dispatch Cargo Orders / Trips", 5.0, 3.4),
        ("Perform Pre/Post-Trip Inspections", 5.0, 2.5),
        ("Log Fuel Receipts via OCR / Analytics", 5.0, 1.6),
        ("Schedule Repairs & Update Work Orders", 5.0, 0.7)
    ]
    for text, x, y in use_cases:
        ellipse = patches.Ellipse((x, y), 3.8, 0.65, fc="#EFF6FF", ec="#3B82F6", lw=1.5)
        ax.add_patch(ellipse)
        ax.text(x, y, text, ha='center', va='center', fontsize=8.2, color='#1E40AF', fontweight='medium')

    # Connect lines from actors
    # Manager
    for uy in [5.2, 4.3, 3.4]:
        ax.plot([1.25, 3.1], [4.5, uy], color="#9CA3AF", lw=1.2, ls="--")
    # Driver
    for uy in [5.2, 3.4, 2.5, 1.6]:
        ax.plot([1.25, 3.1], [2.0, uy], color="#9CA3AF", lw=1.2, ls="--")
    # Maintenance
    for uy in [5.2, 2.5, 0.7]:
        ax.plot([8.75, 6.9], [3.2, uy], color="#9CA3AF", lw=1.2, ls="--")

    ax.set_xlim(0, 10)
    ax.set_ylim(0, 6.5)
    plt.tight_layout()
    plt.savefig('./Internship_report_and_ppt/assets/uml_usecase.png', dpi=300, facecolor=fig.get_facecolor(), edgecolor='none')
    plt.close()

# 5. UML Sequence Diagram (Authentication & 2FA Flow)
def create_uml_sequence():
    fig, ax = plt.subplots(figsize=(10, 6.5), dpi=300)
    ax.axis('off')
    fig.patch.set_facecolor('#F8FAFC')
    ax.set_facecolor('#F8FAFC')

    lifelines = [
        ("User\n(Actor)", 1.2),
        ("SignInView\n(SwiftUI)", 3.4),
        ("AuthViewModel\n(State/Logic)", 5.6),
        ("Supabase Auth\n(Cloud BaaS)", 7.8),
        ("ContentView\n(Router)", 9.2)
    ]

    for name, x in lifelines:
        box = patches.FancyBboxPatch((x-0.8, 5.7), 1.6, 0.6, boxstyle="round,pad=0.08", fc="#DBEAFE", ec="#2563EB", lw=1.5)
        ax.add_patch(box)
        ax.text(x, 6.0, name, ha='center', va='center', fontsize=8, fontweight='bold', color='#1E40AF', multialignment='center')
        ax.plot([x, x], [0.5, 5.7], color="#9CA3AF", lw=1.2, ls=":")

    # Message arrows
    steps = [
        ("1. Input Email & Password", 1.2, 3.4, 5.2, "->"),
        ("2. signIn(email, password, role)", 3.4, 5.6, 4.8, "->"),
        ("3. Verify Credentials & Request OTP", 5.6, 7.8, 4.4, "->"),
        ("4. OTP Dispatched (or Offline Predefined)", 7.8, 5.6, 4.0, "-->"),
        ("5. isWaitingForOTP = true (Render OTP UI)", 5.6, 3.4, 3.6, "-->"),
        ("6. User enters 6-digit OTP", 1.2, 3.4, 3.1, "->"),
        ("7. verifyOTP(token: '123456')", 3.4, 5.6, 2.7, "->"),
        ("8. Validate Token & Fetch User Profile", 5.6, 7.8, 2.3, "->"),
        ("9. Return Valid Session & JWT", 7.8, 5.6, 1.9, "-->"),
        ("10. isAuthenticated = true & Save Session", 5.6, 9.2, 1.4, "->"),
        ("11. Route to Role View (Manager/Driver/Maint)", 9.2, 1.2, 0.9, "-->")
    ]

    for label, x1, x2, y, style in steps:
        ls = "--" if "--" in style else "-"
        arr = "->" if x2 > x1 else "<-"
        ax.annotate("", xy=(x2, y), xytext=(x1, y),
                    arrowprops=dict(arrowstyle="->", color="#1F2937", lw=1.3, linestyle=ls))
        mid = (x1 + x2) / 2
        ax.text(mid, y + 0.12, label, ha='center', va='bottom', fontsize=7.2, color='#1E3A8A', fontweight='medium')

    ax.set_xlim(0.2, 10)
    ax.set_ylim(0.4, 6.6)
    plt.tight_layout()
    plt.savefig('./Internship_report_and_ppt/assets/uml_sequence_auth.png', dpi=300, facecolor=fig.get_facecolor(), edgecolor='none')
    plt.close()

# 6. JIRA Agile Workflow & Sprint Burndown
def create_jira_agile_diagram():
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11, 4.8), dpi=300)
    fig.patch.set_facecolor('#F8FAFC')
    
    # Left: JIRA Board Stages
    ax1.set_facecolor('#F8FAFC')
    ax1.axis('off')
    ax1.set_title("Agile Scrum Lifecycle in Atlassian JIRA", fontsize=11, fontweight='bold', color='#1E40AF', pad=15)
    
    stages = [
        ("Product\nBacklog", 0.5, "#E2E8F0", "#64748B"),
        ("Sprint\nBacklog", 2.2, "#FEF3C7", "#D97706"),
        ("In\nProgress", 3.9, "#DBEAFE", "#2563EB"),
        ("Testing &\nCode Review", 5.6, "#F3E8FF", "#9333EA"),
        ("Done /\nShipped", 7.3, "#DCFCE7", "#16A34A")
    ]
    for name, x, bg, border in stages:
        rect = patches.FancyBboxPatch((x, 1.5), 1.3, 1.8, boxstyle="round,pad=0.1", fc=bg, ec=border, lw=1.8)
        ax1.add_patch(rect)
        ax1.text(x+0.65, 2.4, name, ha='center', va='center', fontsize=8, fontweight='bold', color='#1E293B', multialignment='center')
        if x < 7.0:
            ax1.annotate("", xy=(x+1.5, 2.4), xytext=(x+1.3, 2.4),
                         arrowprops=dict(arrowstyle="->", color="#475569", lw=1.5))
            
    ax1.text(4.4, 0.7, "Team Size: 10 Members | 2-Week Sprints | Daily Standups", ha='center', va='center',
             fontsize=8.5, fontstyle='italic', color='#475569')
    ax1.set_xlim(0, 9)
    ax1.set_ylim(0.2, 4.0)

    # Right: Sprint Burndown Chart
    ax2.set_facecolor('#FFFFFF')
    ax2.set_title("Sprint 3 Burndown Chart (Story Points)", fontsize=11, fontweight='bold', color='#1E40AF', pad=15)
    days = [f"D{i}" for i in range(1, 11)]
    ideal = [50 - (50/9)*i for i in range(10)]
    actual = [50, 48, 44, 42, 35, 28, 22, 14, 6, 0]
    
    ax2.plot(days, ideal, label="Ideal Burn Line", color="#94A3B8", linestyle="--", linewidth=2)
    ax2.plot(days, actual, label="Actual Progress", color="#2563EB", marker="o", linewidth=2.5)
    ax2.fill_between(days, actual, color="#DBEAFE", alpha=0.3)
    ax2.set_ylabel("Remaining Story Points", fontsize=8.5, fontweight='bold', color="#1E293B")
    ax2.set_xlabel("Sprint Days (2 Weeks)", fontsize=8.5, fontweight='bold', color="#1E293B")
    ax2.grid(True, linestyle=":", alpha=0.6)
    ax2.legend(loc="upper right", fontsize=8)
    ax2.tick_params(axis='both', which='major', labelsize=8)

    plt.tight_layout()
    plt.savefig('./Internship_report_and_ppt/assets/jira_agile_workflow.png', dpi=300, facecolor=fig.get_facecolor(), edgecolor='none')
    plt.close()

# 7. App UI Flow & Composite Screens
def create_app_ui_flow():
    fig, ax = plt.subplots(figsize=(11, 4.8), dpi=300)
    ax.axis('off')
    fig.patch.set_facecolor('#F8FAFC')
    ax.set_facecolor('#F8FAFC')

    screens = [
        ("Role Selection", "• Fleet Manager\n• Driver\n• Maintenance\nDynamic Theme Colors", 1.3, "#0D9488"),
        ("Secure SignIn", "• Predefined Demo ID\n• Password Auth\n• Quick-Fill Card\n• Client Validation", 3.8, "#0284C7"),
        ("2FA OTP Verification", "• 6-Digit Predefined OTP\n• Auto-Fill Helper\n• Error Resilience\n• Session Token Issue", 6.3, "#7C3AED"),
        ("Role Dashboard", "• Live GPS Map Tracking\n• Trip Management\n• Work Orders & OCR\n• Realtime Pub-Sub", 8.8, "#16A34A")
    ]

    for title, desc, x, color in screens:
        # Mock phone bezel
        bezel = patches.FancyBboxPatch((x-1.0, 0.4), 2.0, 3.8, boxstyle="round,pad=0.15", fc="#FFFFFF", ec=color, lw=2.5)
        ax.add_patch(bezel)
        # Phone top notch
        notch = patches.Rectangle((x-0.4, 4.05), 0.8, 0.1, fc="#E2E8F0", ec="none")
        ax.add_patch(notch)
        # Header bar
        hbar = patches.Rectangle((x-0.95, 3.5), 1.9, 0.5, fc=color, ec="none")
        ax.add_patch(hbar)
        ax.text(x, 3.75, title, ha='center', va='center', fontsize=8, fontweight='bold', color="#FFFFFF")
        # Text description
        ax.text(x-0.85, 2.2, desc, ha='left', va='center', fontsize=7.5, color="#334155", linespacing=1.6)
        # Bottom home indicator
        bind = patches.Rectangle((x-0.35, 0.55), 0.7, 0.05, fc="#94A3B8", ec="none")
        ax.add_patch(bind)

        if x < 8.0:
            ax.annotate("", xy=(x+1.15, 2.3), xytext=(x+1.0, 2.3),
                         arrowprops=dict(arrowstyle="->", color="#64748B", lw=2))

    ax.set_xlim(0, 10.2)
    ax.set_ylim(0.1, 4.5)
    plt.tight_layout()
    plt.savefig('./Internship_report_and_ppt/assets/app_ui_flow.png', dpi=300, facecolor=fig.get_facecolor(), edgecolor='none')
    plt.close()

if __name__ == "__main__":
    print("Generating diagrams...")
    create_architecture_diagram()
    create_dfd_level0()
    create_dfd_level1()
    create_uml_usecase()
    create_uml_sequence()
    create_jira_agile_diagram()
    create_app_ui_flow()
    print("All diagrams generated successfully!")
