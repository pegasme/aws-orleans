# aws-orleans
Deploy to AWS and test Microsoft Orleans

Sample project: https://learn.microsoft.com/en-us/dotnet/orleans/tutorials-and-samples/adventure
https://github.com/dotnet/samples/tree/main/orleans/Adventure


//
Make sure that /usr/local/bin is in your $PATH.

      - name: Deploy to S3
        uses: jakejarvis/s3-sync-action@v0.5.1
        with:
          args: --acl public-read --delete
        env:
          AWS_S3_BUCKET: ${{ secrets.AWS_S3_BUCKET }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}