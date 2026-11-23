workspace "TodoItems" "The TodoItems demo API as used in the Azure networking workshop." {

    !identifiers hierarchical

    model {
        u = person "User" "Calls the API."

        ss = softwareSystem "TodoItems" "Demo API to manage a to-do list. One instance per pipeline run, in its own resource group." {
            api = container "TodoItems API" "Minimal API: CRUD on todoitems." "ASP.NET Core, Azure App Service"
            db = container "Database" "Stores the to-do items." {
                tags "Database"
            }
            kv = container "Key Vault" "Holds the database connection string." "Azure Key Vault"
            monitor = container "Application Insights" "Telemetry and logging of the API" "Application Insights, Log Analytics" {
                tags "Monitoring"
            }
        }

        cal = softwareSystem "Calendar API" "Business-day calculator that knows the holidays per country: Owned by another team. Internal only." {
            tags "Other team"
        }

        u -> ss.api "Sends requests to" "HTTPS"
        ss.api -> cal "Asks for the due date of a new item" "HTTPS"
        ss.api -> ss.db "Reads from and writes to" "SQL"
        ss.api -> ss.kv "Gets the connection string from" "HTTPS"
        ss.api -> ss.monitor "Sends telemetry to" "HTTPS"

        // Assignment 2: the network. Every resource group is a hub or a spoke with its own virtual network.
        // The web apps are not part of this picture: they only get a place in a network in the next assignments.
        net = deploymentEnvironment "Assignment 2" {
            // A group draws a boundary around everything inside it, without an extra level in the model.
            // The order of the blocks matters: the automatic layout decides left and right from it
            // (tested: with this group, TodoItems first puts spoke 1 on the left).
            group "Azure subscription" {
                hub = deploymentNode "Hub resource group" "Shared network of all spokes" "Azure resource group" {
                    tags "Microsoft Azure - Resource Groups"

                    // The address ranges are in the names of the frames: Structurizr does not show the description of a deployment node.
                    vnet = deploymentNode "Hub virtual network (10.0.0.0/16)" "" "Azure virtual network" {
                        tags "Microsoft Azure - Virtual Networks"

                        // The order of the boxes in the hub decides where the spokes end up: each spoke is drawn under its peering box,
                        // The firewall sits between the two peering boxes, so it is drawn above the gap between the spokes.
                        // (The line of the first peering crosses the labels of the hub frames: accepted.)
                        // A peering is a resource on each virtual network (one per direction).
                        peeringTodo = infrastructureNode "Peering to spoke 1" "" "Virtual network peering" {
                            tags "Microsoft Azure - Peerings"
                        }

                        // The firewall itself, with its subnet in the description (Azure requires the name AzureFirewallSubnet).
                        firewall = infrastructureNode "Azure Firewall" "AzureFirewallSubnet 10.0.2.0/26" "Azure Firewall" {
                            tags "Microsoft Azure - Firewalls"
                        }

                        peeringCalendar = infrastructureNode "Peering to spoke 2" "" "Virtual network peering" {
                            tags "Microsoft Azure - Peerings"
                        }

                        // Still empty in this assignment. Infrastructure nodes, because Structurizr leaves empty deployment nodes out of a view.
                        shared = infrastructureNode "sharedServicesSubNet" "10.0.1.0/24" "Subnet" {
                            tags "Microsoft Azure - Subnet"
                        }
                    }
                }

                todo = deploymentNode "TodoItems resource group (spoke 1)" "" "Azure resource group" {
                    tags "Microsoft Azure - Resource Groups"

                    vnet = deploymentNode "Spoke 1 virtual network (10.1.0.0/16)" "" "Azure virtual network" {
                        tags "Microsoft Azure - Virtual Networks"

                        peering = infrastructureNode "Peering to hub" "" "Virtual network peering" {
                            tags "Microsoft Azure - Peerings"
                        }

                        workload = deploymentNode "workloadSubnet (10.1.1.0/24)" "" "Subnet" {
                            tags "Microsoft Azure - Subnet"

                            vm = infrastructureNode "Virtual machine" "To test the network" "Azure virtual machine" {
                                tags "Microsoft Azure - Virtual Machine"
                            }
                        }
                    }
                }

                calendar = deploymentNode "Calendar resource group (spoke 2)" "" "Azure resource group" {
                    tags "Microsoft Azure - Resource Groups"

                    vnet = deploymentNode "Spoke 2 virtual network (10.2.0.0/16)" "" "Azure virtual network" {
                        tags "Microsoft Azure - Virtual Networks"

                        peering = infrastructureNode "Peering to hub" "" "Virtual network peering" {
                            tags "Microsoft Azure - Peerings"
                        }

                        workload = deploymentNode "workloadSubnet (10.2.1.0/24)" "" "Subnet" {
                            tags "Microsoft Azure - Subnet"

                            vm = infrastructureNode "Virtual machine" "To test the network" "Azure virtual machine" {
                                tags "Microsoft Azure - Virtual Machine"
                            }
                        }
                    }
                }
            }
        }

        // Each spoke is connected to the hub, not to each other.
        // The lines go between the peering boxes: Structurizr cannot lay out a line that ends at a box that contains other boxes.
        net.hub.vnet.peeringTodo -> net.todo.vnet.peering "Peering"
        net.hub.vnet.peeringCalendar -> net.calendar.vnet.peering "Peering"
    }

    views {
        systemContext ss "SystemOverview" {
            title "TodoItems: system context"
            include *
        }

        container ss "ContainerOverview" {
            title "TodoItems: containers"
            include *
        }

        deployment ss "Assignment 2" "NetworkOverview" {
            title "Assignment 2: hub and two spokes"
            include *
            // tb = hub on top. First number: distance between the hub and the spokes (below about 150 the boxes start to overlap).
            // Second number: distance between boxes next to each other.
            autoLayout tb 200 120
        }

        // Azure icons, matched on the tags "Microsoft Azure - ..." of the elements.
        // From GitHub: static.structurizr.com (the Structurizr cloud service) ended on 30 September 2026.
        theme https://raw.githubusercontent.com/structurizr/themes/master/microsoft-azure-2023.01.24/theme.json

        styles {
            element "Element" {
                color #0773af
                stroke #0773af
                strokeWidth 7
                shape roundedbox
            }
            element "Person" {
                shape person
            }
            element "Database" {
                shape cylinder
            }
            element "Other team" {
                border dashed
            }
            // The boundary around the whole network (the group "Azure subscription").
            element "Group:Azure subscription" {
                color #1b3a57
                stroke #1b3a57
                strokeWidth 3
                border dashed
                fontSize 28
            }
            element "Boundary" {
                strokeWidth 5
            }
            // The network diagram has many nested boxes: thinner lines and readable (dark) labels.
            element "Deployment Node" {
                strokeWidth 3
            }
            // After the Azure theme on purpose: the theme colors the resource group label light blue and it is hard to read.
            element "Microsoft Azure - Resource Groups" {
                color #1b3a57
                stroke #50a0d8
            }
            element "Infrastructure Node" {
                strokeWidth 3
            }
            relationship "Relationship" {
                thickness 4
            }
        }
    }

    configuration {
        scope softwaresystem
    }

}
