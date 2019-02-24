package main

import (
	"log"

	"github.com/spf13/cobra"

	"suse.com/caaspctl/internal/pkg/caaspctl/deployments/salt"
	"suse.com/caaspctl/pkg/caaspctl/actions/deletenode"
)

func newDeleteNodeCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "delete-node <target>",
		Short: "Delete a node from the cluster",
		Run: func(cmd *cobra.Command, targets []string) {
			saltPath, err := cmd.Flags().GetString("salt-path")
			if err != nil {
				log.Fatalf("Unable to parse salt flag: %v", err)
			}
			user, err := cmd.Flags().GetString("user")
			if err != nil {
				log.Fatalf("Unable to parse user flag: %v", err)
			}
			sudo, err := cmd.Flags().GetBool("sudo")
			if err != nil {
				log.Fatalf("Unable to parse sudo flag: %v", err)
			}

			target := salt.Target{
				Node: targets[0],
				User: user,
				Sudo: sudo,
			}

			masterConfig := salt.NewMasterConfig(
				target,
				saltPath,
			)

			deletenode.DeleteNode(masterConfig)
		},
		Args: cobra.ExactArgs(1),
	}

	cmd.Flags().StringP("user", "u", "root", "User identity used to connect to target")
	cmd.Flags().Bool("sudo", false, "Run remote command via sudo")

	cmd.Flags().StringP("salt-path", "s", "", "Salt root path to the states folder")
	cmd.MarkFlagRequired("salt-path")

	return cmd
}