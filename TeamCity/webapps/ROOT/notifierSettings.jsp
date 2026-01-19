<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="profile" tagdir="/WEB-INF/tags/userProfile" %>
<jsp:useBean id="notifierSettingsForm" type="jetbrains.buildServer.controllers.profile.notifications.NotifierSettingsForm" scope="request"/>
<jsp:useBean id="currentUser" type="jetbrains.buildServer.users.SUser" scope="request"/>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.controllers.OptionPropertiesBean" scope="request"/>
<ext:includeExtensions placeId="<%=PlaceId.NOTIFIER_SETTINGS_FRAGMENT%>"/>

<bs:messages key="settingsUpdated" style="margin-left: 0; width: 53em;"/>
<bs:messages key="settingsError" style="margin-left: 0; width: 53em;" isWarning="true"/>

<c:set var="hasPermissionsToEditNotifierSettingsForm"
       value="${notifierSettingsForm.editee.id == currentUser.id && afn:permissionGrantedGlobally('CHANGE_OWN_PROFILE') || afn:permissionGrantedGlobally('CHANGE_USER')}"/>

<c:if test="${(not empty notifierSettingsForm.parameters or not empty notifierSettingsForm.editUrl) and hasPermissionsToEditNotifierSettingsForm}">
  <div class="notifierSettings clearfix">
    <c:set var="parameters" value="${notifierSettingsForm.parameters}"/>
    <form id="notifierSettingsForm" action="<c:url value='/notifierSettings.html'/>" method="POST" onsubmit="return BS.NotifierPropertiesForm.submitSettings()">
      <div class="notifierSettingControls">
        <table>
          <c:choose>
            <c:when test="${not empty notifierSettingsForm.editUrl}">
              <jsp:include page="${notifierSettingsForm.editUrl}">
                <jsp:param name="holderId" value="${notifierSettingsForm.editee.id}"/>
              </jsp:include>
            </c:when>
            <c:otherwise>

              <c:forEach items="${parameters}" var="parameter" varStatus="pos">
                <c:set var="propertyField" value="${util:forJS(parameter.name, true, false)}"/>
                <tr>
                  <td>
                    <label class="notifierSettingControls__label">
                        ${util:forJS(parameter.controlDescription.parameterTypeArguments["description"], false, true)}:<c:if
                        test="${parameter.controlDescription.parameterTypeArguments['required'] == 'true'}"><l:star/></c:if>
                    </label>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${parameter.controlDescription.parameterType == 'password'}">
                        <props:passwordProperty name="${propertyField}" className="longField" style="width: 28em;"/>
                      </c:when>

                      <c:when test="${parameter.controlDescription.parameterType == 'selection'}">
                        <c:set var="options" value="${propertiesBean.options[parameter.name]}"/>

                        <props:selectProperty name="${propertyField}" className="longField" style="width: 28em;">
                          <c:forEach items="${options}" var="option">
                            <props:option value="${util:forJS(option.value, true, false)}">
                              <bs:out value="${option.displayName}"/>
                            </props:option>
                          </c:forEach>
                        </props:selectProperty>
                      </c:when>

                      <c:otherwise>
                        <props:textProperty name="${propertyField}" className="longField" style="width: 28em;"/>

                        <c:set var="hintUrl" value="${parameter.controlDescription.parameterTypeArguments['hintUrl']}"/>

                        <c:if test="${not empty hintUrl}">
                          <forms:saving id="saving_${propertyField}" style="display: none;"/>

                          <script type="text/javascript">
                            var parameters = [];
                            <c:forEach var="p" items="${parameters}">
                            parameters.push("${util:forJS(p.name, true, false)}");
                            </c:forEach>

                            $j(document.getElementById("${propertyField}")).autocomplete({
                              source: BS.NotifierPropertiesForm.createSourceFunction(window["base_uri"] + "${hintUrl}", "${propertyField}", parameters),
                              search: BS.NotifierPropertiesForm.createSearchFunction("${propertyField}")
                            });

                            $j(document.getElementById("${propertyField}")).placeholder();
                          </script>
                        </c:if>
                      </c:otherwise>
                    </c:choose>
                    <span class="error" id="error_${propertyField}"></span>
                  </td>
                </tr>
              </c:forEach>


            </c:otherwise>
          </c:choose>
        </table>
      </div>
      <br/>
      <input type="hidden" name="notificatorType" value="${notifierSettingsForm.notificator.notificatorType}"/>
      <input type="hidden" name="userId" value="${notifierSettingsForm.editee.id}"/>
      <span id="additionalNotifierButtonsBefore"></span>
      <input type="submit" value="Save" class="btn btn_mini submitButton" id="saveNotifierSettings"/>
      <span id="additionalNotifierButtonsAfter"></span>
      <forms:saving id="saving_settings"/>
    </form>
  </div>

</c:if>


<div id="notificationRulesPage">
<jsp:include page="/notificationRules.html?notificatorType=${notifierSettingsForm.notificator.notificatorType}&holderId=user:${notifierSettingsForm.editee.id}"/>
</div>
