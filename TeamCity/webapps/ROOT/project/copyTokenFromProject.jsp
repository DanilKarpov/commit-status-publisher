<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.impl.ProjectEx" scope="request"/>

<jsp:useBean id="token" type="java.lang.String" scope="request"/>
<jsp:useBean id="description" type="java.lang.String" scope="request"/>
<jsp:useBean id="fixes" type="java.util.List<jetbrains.buildServer.serverSide.SProject>" scope="request"/>

<c:url var="copyTokensFromProject" value="/admin/copyTokensFromProject.html"/>

<c:set var="copyTokenTitle" value="Copy value for token from other projects"/>

<bs:linkCSS>
  /css/admin/adminMain.css
</bs:linkCSS>

<c:choose>
  <c:when test="${fn:length(fixes) == 1}">
    <div style="padding: 8px 8px 0px 8px;">
      There is a secure value for the token <span class="smallNote token" style="margin-left: 0"><bs:out value="${token}"/></span>
      in the project
      <admin:editProjectLink projectId="${fixes[0].externalId}"><c:out value="${fixes[0].fullName}"/></admin:editProjectLink>
    </div>
  </c:when>
  <c:otherwise>
    <div style="padding: 8px 8px 0px 8px;">
      There are different secure values for the token <span class="smallNote token" style="margin-left: 0"><bs:out value="${token}"/></span>
      in different projects.
    </div>
    <table class="runnerFormTable">
      <tr>
        <td><label for="copyTokenSelect">Project with secure value:</label></td>
        <td>
          <forms:select name="copyTokenSelect" style="width: 25em;" enableFilter="true">
            <forms:projectOptions selected="${fixes[0]}" projects="${fixes}" showFullNames="true"/>
          </forms:select>
        </td>
      </tr>
    </table>
  </c:otherwise>
</c:choose>

<div class="popupSaveButtonsBlock">
  <forms:button onclick="BS.CopyTokenFromProjectForm.save(); return false" className="btn_primary" id="copyTokenFromProjectFormButton" showdiscardchangesmessage="false">
    Copy Secure Value
  </forms:button>
  <forms:saving id="copyTokenFromProjectFormProgress" savingTitle="Copying token..."/>
</div>

<bs:executeOnce id="copyTokenFromProject">
  <script>
    BS.CopyTokenFromProjectForm = OO.extend(BS.AbstractWebForm, {
      singleOption: ${fn:length(fixes) == 1},
      singleProjectId: "${util:forJS(fixes[0].projectId, true, false)}",

      getForm: function () {
        return $j('#copyTokenFromProjectForm');
      },

      getProgress: function () {
        return $j('#copyTokenFromProjectFormProgress');
      },

      getButton: function () {
        return $j('#copyTokenFromProjectFormButton');
      },

      getSelect: function () {
        return $j("#copyTokenSelect")
      },

      showDialog: function () {
        this.getForm().show();
      },

      save: function () {
        var self = this;
        this.getProgress().show();
        this.getButton().attr("disabled", true);

        var projectId;

        if (this.singleOption) {
          projectId = this.singleProjectId;
        } else {
          projectId = this.getSelect().find("option:selected").val();
        }

        $j.ajax({
          url: '${copyTokensFromProject}?projectId=${project.externalId}',
          data: JSON.stringify({
            tokens: [
              {
                token: '${util:forJS(token, false, false)}',
                projectId: projectId
              }
            ]
          }),
          type: "POST",
          success: function () {
            BS.reload(true);
          },
          error: function () {
            self.getProgress().hide();
            self.getButton().attr("disabled", false);
          },
          contentType: 'application/json'
        });
      }
    });
  </script>

  <style>
    #copyTokenFromProject {
      width: 40em;
    }

    #copyTokenFromProjectFormButton {
      margin-left: 8px;
    }
  </style>
</bs:executeOnce>