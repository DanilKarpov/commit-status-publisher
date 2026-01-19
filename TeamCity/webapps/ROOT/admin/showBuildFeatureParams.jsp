<%@include file="/include-internal.jsp"%>
<jsp:useBean id="buildFeature" type="jetbrains.buildServer.serverSide.BuildFeature" scope="request"/>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>

<table class="runnerFormTable featureDetails">
  <div id="build-feature-type-holder" data-feature-type="${buildForm.buildFeaturesBean.featureType}"></div>
  <c:if test="${not empty buildFeature.editParametersUrl}">
    <jsp:include page="${buildFeature.editParametersUrl}"/>
  </c:if>
</table>
<c:choose>
  <c:when test="${buildForm.readOnly}">
    <script type="text/javascript">
      BS.BuildFeatureDialog.setReadOnly([{name: 'featureTypeSelector'}, {className: 'submitButton'}, {name: 'buildFailureOnMessage.finishedBuildId'}]);
    </script>
    <authz:authorize projectId="${buildForm.project.projectId}" allPermissions="EDIT_PROJECT">
      <jsp:attribute name="ifAccessGranted">
        <script type="text/javascript">
          $('featureSaveButtonsBlock').show();
          $('submitBuildFeatureId').hide();
          $('cancelBuildFeature').hide();
          $j('div#dialogDslButtons').hide();
        </script>
      </jsp:attribute>
      <jsp:attribute name="ifAccessDenied">
        <script type="text/javascript">
          $('featureSaveButtonsBlock').hide();
        </script>
      </jsp:attribute>
    </authz:authorize>
  </c:when>
  <c:otherwise>
    <script type="text/javascript">
      $('featureSaveButtonsBlock').show();
      $('submitBuildFeatureId').show();
      $('cancelBuildFeature').show();
      $j('div#dialogDslButtons').show();
    </script>
  </c:otherwise>
</c:choose>

<admin:showHideAdvancedOpts containerId="buildFeatures" optsKey="buildFeatures"/>
<admin:highlightChangedFields containerId="buildFeatures"/>
