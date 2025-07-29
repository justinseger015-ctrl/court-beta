<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><cfoutput>#application.siteTitle ?: "DocketWatch"#</cfoutput> - Login</title>
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #f8f9fa;
        }
        .login-container {
            max-width: 400px;
            margin: 100px auto;
        }
        .card {
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="login-container">
            <div class="card">
                <div class="card-header text-center">
                    <h4><cfoutput>#application.siteTitle ?: "DocketWatch"#</cfoutput></h4>
                    <p class="text-muted">Please sign in to continue</p>
                </div>
                <div class="card-body">
                    <cfif isDefined("Login_Message")>
                        <div class="alert alert-danger">
                            <cfoutput>#Login_Message#</cfoutput>
                        </div>
                    </cfif>
                    
                    <form method="post" action="">
                        <div class="mb-3">
                            <label for="j_username" class="form-label">Username</label>
                            <input type="text" class="form-control" name="j_username" id="j_username" required autofocus>
                        </div>
                        
                        <div class="mb-3">
                            <label for="j_password" class="form-label">Password</label>
                            <input type="password" class="form-control" name="j_password" id="j_password" required>
                        </div>
                        
                        <div class="d-grid">
                            <button type="submit" class="btn btn-primary">Sign In</button>
                        </div>
                    </form>
                </div>
                <div class="card-footer text-center text-muted">
                    <small>© 2025 TMZ. All rights reserved.</small>
                </div>
            </div>
        </div>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
