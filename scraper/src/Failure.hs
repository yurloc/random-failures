{-# LANGUAGE DeriveAnyClass    #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Failure where
import           Data.Aeson      (FromJSON, ToJSON, parseJSON, withObject,
                                  (.!=), (.:), (.:?))
import           Data.Text       (Text)
import           Data.Time.Clock (UTCTime)
import           GHC.Generics    (Generic)

{-| JenkinsTestResult serves as input for our analyis.
    It comes from $BUILD_URL/testReport/api/json?tree=suites[cases[className,errorDetails,errorStackTrace,name,status]]
    It contains the following data about each test executed

{ "className": "org.optaplanner.openshift.employeerostering.webapp.skill.SkillRestServiceIT"
, "errorDetails": null
, "errorStackTrace": null
, "name": "testDeleteNonExistingSkill"
, "status": "PASSED"
}
-}

data JenkinsTestResult = JenkinsTestResult
    { resultClass      :: !Text
    , resultMethod     :: !Text
    , resultStackTrace :: !Text
    , resultStatus     :: !Text -- Possible status values seem to be : PASSED, SKIPPED, FAILED, REGRESSION, FIXED
    } deriving (Show, Generic, ToJSON)

instance FromJSON JenkinsTestResult where
  parseJSON = withObject "Fail" $ \o -> do
    resultClass <- o .: "className"
    resultMethod <- o .: "name"
    resultStackTrace <- o .:? "errorStackTrace" .!= ""
    resultStatus <- o .: "status"
    return JenkinsTestResult{..}

isFailure :: JenkinsTestResult -> Bool
isFailure result =
    let status = resultStatus result
    in status == "REGRESSION" || status == "FAILED"

toFailure :: Text -> UTCTime ->  JenkinsTestResult -> TestFailure
toFailure buildUrl builtOn result = TestFailure
    { url        = buildUrl
    , date       = builtOn
    , testClass  = resultClass result
    , testMethod = resultMethod result
    , stackTrace = resultStackTrace result
    }

{-| TestFailure represents similar data which,
in addition to JenkinsTestResults also contains date of failure and build URL
-}
data TestFailure = TestFailure
    { url        :: !Text
    , date       :: !UTCTime
    , testClass  :: !Text
    , testMethod :: !Text
    , stackTrace :: !Text
    } deriving (Eq, Show, Generic, ToJSON, FromJSON)