<%@include file="/include-internal.jsp"%>
<jsp:useBean id="projectDataBean" type="jetbrains.buildServer.controllers.admin.ProjectDataFetcherController.ProjectDataBean" scope="request"/>

<c:set var="itemName" value="dataItem_${projectDataBean.targetFieldId}"/>
<c:set var="formId" value="projectDataForm_${projectDataBean.targetFieldId}"/>

<%--@elvariable id="projectData" type="java.util.Map"--%>
<c:if test="${projectData != null}">
<div class="projectDataContainer">
  <form id="${formId}">
  <c:choose>
    <c:when test="${not empty projectData}">
      <bs:smallNote><c:out value='${projectDataBean.popupTitle}'/>:</bs:smallNote>
      <c:choose>
        <c:when test="${'multiple' == projectDataBean.selectionMode}">
          <c:set var="buttonCaption" value="Add"/>
          <c:set var="onsubmit" value="BS.ProjectDataPopup.appendSelectedValues('${formId}', '${projectDataBean.targetFieldId}')"/>
          <c:if test="${fn:length(projectData) > 10}">
            <bs:inplaceFilter containerId="${formId}"
                              activate="true"
                              filterText="&lt;filter items>"/>
          </c:if>
          <ul class="itemsList">
            <c:forEach items="${projectData}" var="item" varStatus="pos">
              <li class="inplaceFiltered">
                <forms:checkbox id="${itemName}_${pos.index}" name="${itemName}" value="${fn:escapeXml(item.value)}"/>
                <label for="${itemName}_${pos.index}"><c:out value="${item.value}"/></label>
                <c:if test="${fn:length(item.details) > 0}">
                  <em class="grayNote">(<c:out value="${item.details}"/>)</em>
                </c:if>
              </li>
            </c:forEach>
          </ul>
        </c:when>
        <c:when test="${'single' == projectDataBean.selectionMode}">
          <c:set var="buttonCaption" value="Insert"/>
          <c:set var="onsubmit" value=""/>
          <ul class="menuList">
            <c:forEach items="${projectData}" var="item" varStatus="pos">
              <c:set var="escapedVal"><bs:escapeForJs text="${item.value}"/></c:set>
              <li onclick="BS.ProjectDataPopup.insertSelectedValue('${escapedVal}', '${projectDataBean.targetFieldId}')"><c:out value="${item.value}"/></li>
            </c:forEach>
          </ul>
        </c:when>
      </c:choose>

      <c:if test="${'multiple' == projectDataBean.selectionMode}">
      <div class="popupSaveButtonsBlock">
        <forms:submit type="button" label="${buttonCaption}" onclick="${onsubmit}"/>
        <forms:cancel onclick="BS.ProjectDataPopup.hidePopup(0)"/>
      </div>
      </c:if>
    </c:when>
    <c:otherwise>
      No items to show
    </c:otherwise>
  </c:choose>
  </form>
</div>
</c:if>

<c:if test="${projectDataBean.canFetchData and projectData == null}">
<script type="text/javascript">
  BS.ProjectDataPopup.attachHandler('${projectDataBean.type}', '${projectDataBean.sourceFieldId}', '${projectDataBean.targetFieldId}', '${projectDataBean.popupTitle}');
</script>
</c:if>
