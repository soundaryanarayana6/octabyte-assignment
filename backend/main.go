package main

import (
	"context"
	"encoding/json"
	"net/http"
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	r := gin.Default()

	r.GET("/health", healthCheck)

	r.Run(":8080")
}

func healthCheck(c *gin.Context) {
	if os.Getenv("SKIP_DB_CHECK") == "true" {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
		return
	}

	region := os.Getenv("AWS_REGION")
	if region == "" {
		region = "us-east-1"
	}

	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(region),
	}))
	svc := secretsmanager.New(sess)

	env := os.Getenv("ENV")
	if env == "" {
		env = "dev"
	}

	input := &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(env + "-db-password"),
	}

	result, err := svc.GetSecretValue(input)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch secret"})
		return
	}

	var secret map[string]string
	err = json.Unmarshal([]byte(*result.SecretString), &secret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse secret"})
		return
	}

	rdsEndpoint := os.Getenv("RDS_ENDPOINT")
	if rdsEndpoint == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "RDS_ENDPOINT not configured"})
		return
	}

	dbName := "mydb"
	dbPort := "5432"

	dbURL := "postgres://" + secret["username"] + ":" + secret["password"] + "@" + rdsEndpoint + ":" + dbPort + "/" + dbName

	pool, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to DB"})
		return
	}
	defer pool.Close()

	var version string
	err = pool.QueryRow(context.Background(), "SELECT version()").Scan(&version)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to query DB"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}