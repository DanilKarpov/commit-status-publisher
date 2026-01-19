<%@ page import="jetbrains.buildServer.serverSide.BuildTypeOptions" %>
<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<c:set var="cameFrom" value='<%=WebUtil.encode(request.getAttribute("pageUrl") + "&init=1")%>'/>
<admin:editBuildTypePage selectedStep="buildFailureConditions">
  <jsp:attribute name="head_include">
    <style type="text/css">
      .failureConditions {
        margin-top: 5px;
      }

      .failureConditionItem {
        border-left: 3px solid var(--ring-content-background-color, #fff);
        margin-bottom: .3em;
        padding-left: 0.5em;
      }

      .failureConditionItem label {
        display: inline-block;
        vertical-align: baseline;
      }

      .failureConditionItem span.error {
        margin-left: 10em;
      }

      .failureConditionItem .posRel,
       .editBuildFailureOnMetric .posRel {
        padding-right: 5px;
      }
    </style>
    <script>
      $j(document).ready(function() {
        BS.EditBuildTypeForm.setupEventHandlers();
        BS.EditBuildTypeForm.setModified(${buildForm.stateModified});

        <c:if test="${buildForm.readOnly}">
        BS.EditBuildTypeForm.setReadOnly();
        </c:if>
      });
    </script>
    <%@ include file="editBuildFeaturesResources.jspf" %>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <form action="<c:url value='/admin/editBuild.html?id=${buildForm.settingsId}'/>" method="post"
          onsubmit="return BS.EditBuildTypeForm.submitBuildType()" id="editBuildTypeForm" class="section noMargin">
      <h2 class="noBorder">Common Failure Conditions</h2>
      <bs:smallNote>In this section you can specify when your build should fail.<bs:help file="Build+Failure+Conditions"/></bs:smallNote>

      <div>Fail build if:</div>

      <div class="failureConditions">

        <div class="failureConditionItem">
          <admin:textOption buildTypeForm="${buildForm}" optionName="<%=BuildTypeOptions.BT_EXECUTION_TIMEOUT.getKey()%>" style="width: 6em; font-size:90%;" fieldName="executionTimeout">
            <jsp:attribute name="labelText">it runs longer than specified limit in minutes (0 &mdash; the default will be used)</jsp:attribute>
          </admin:textOption>
          <span class="error" id="errorExecutionTimeout" style="margin-left: 0;"></span>
          <c:if test="${not buildForm.compositeBuild && buildForm.defaultExecutionTimeout > 0}"><span class="smallNote" style="margin-left: 0;">Default execution timeout specified in the server settings: ${buildForm.defaultExecutionTimeout} minute<bs:s val="${buildForm.defaultExecutionTimeout}"/></span></c:if>
        </div>

        <c:if test="${not buildForm.compositeBuild}">
        <div class="failureConditionItem">
          <admin:booleanOption buildTypeForm="${buildForm}" optionName="<%=BuildTypeOptions.BT_FAIL_ON_EXIT_CODE.getKey()%>" fieldName="shouldFailOnExitCode">
            <jsp:attribute name="labelText">one of build steps exited with an error (e.g non-zero exit code in command line runner)</jsp:attribute>
          </admin:booleanOption>
        </div>

        <div class="failureConditionItem">
          <admin:booleanOption buildTypeForm="${buildForm}" optionName="<%=BuildTypeOptions.BT_FAIL_IF_TESTS_FAIL.getKey()%>" fieldName="shouldFailIfTestFailed">
            <jsp:attribute name="labelText">at least one test failed</jsp:attribute>
          </admin:booleanOption>
        </div>

        <div class="failureConditionItem" style="padding-left: 25px">
          <admin:booleanOption buildTypeForm="${buildForm}" optionName="<%=BuildTypeOptions.BT_SUPPORT_TEST_RETRY.getKey()%>" fieldName="supportTestRetry">
            <jsp:attribute name="labelText">support test retry: successful test run mutes previous test failure
            <bs:help file="Build+Failure+Conditions#test-retry"/>
            </jsp:attribute>
          </admin:booleanOption>
        </div>

        <div class="failureConditionItem">
          <admin:booleanOption buildTypeForm="${buildForm}" optionName="<%=BuildTypeOptions.BT_FAIL_ON_ANY_ERROR_MESSAGE.getKey()%>" fieldName="shouldFailBuildOnAnyErrorMessage">
            <jsp:attribute name="labelText">an error message is logged by build runner</jsp:attribute>
          </admin:booleanOption>
        </div>

        <div class="failureConditionItem">
          <admin:booleanOption buildTypeForm="${buildForm}" optionName="<%=BuildTypeOptions.BT_FAIL_ON_OOME_OR_CRASH.getKey()%>" fieldName="shouldFailBuildOnOOMEOrCrash">
            <jsp:attribute name="labelText">an out-of-memory or crash is detected (Java only)</jsp:attribute>
          </admin:booleanOption>
        </div>
        </c:if>
      </div>

      <admin:highlightChangedFields containerId="editBuildTypeForm" closestParentSelector="div.failureConditionItem"/>

      <c:if test="${!buildForm.readOnly}">
        <div class="saveButtonsBlock">
          <forms:submit label="Save"/>
          <forms:cancel cameFromSupport="${buildForm.cameFromSupport}"/>
          <input type="hidden" value="${buildForm.numberOfSettingsChangesEvents}" name="numberOfSettingsChangesEvents"/>
          <input type="hidden" id="submitBuildType" name="submitBuildType" value="1"/>
        </div>
      </c:if>

      <input type="hidden" name="showDSL" id="buildTypeShowDSL" value=""/>
      <input type="hidden" name="showDSLVersion" id="buildTypeShowDSLVersion" value=""/>
      <input type="hidden" name="showDSLPortable" id="buildTypeShowDSLPortable" value=""/>
    </form>

    <div class="section smallMargin">
      <h2 class="noBorder">Additional Failure Conditions</h2>
      <bs:smallNote>In this section you can configure build failure depending on various metrics.<bs:help file="Build+Failure+Conditions#Additional+Failure+Conditions" preservePlus="true"/></bs:smallNote>

      <jsp:include page="/admin/editBuildFeaturesList.html?id=${buildForm.settingsId}&featurePlace=FAILURE_REASON&messagePrefix=Failure+condition"/>
    </div>

    <forms:modified/>
  </jsp:attribute>
</admin:editBuildTypePage>
